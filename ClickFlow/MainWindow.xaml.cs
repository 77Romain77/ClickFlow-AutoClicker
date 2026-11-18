using System.IO;
using System.ComponentModel;
using System.Globalization;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Interop;
using System.Windows.Media;
using System.Windows.Threading;
using ClickFlow.Models;
using ClickFlow.Native;
using ClickFlow.Services;
using Velopack;
using Forms = System.Windows.Forms;

namespace ClickFlow;

public partial class MainWindow : System.Windows.Window
{
    private static readonly int[] GateKeys = { Win32.VkLeft, Win32.VkRight, Win32.VkMiddle, Win32.VkX1, Win32.VkX2 };
    private readonly SettingsStore _store = new();
    private readonly ClickEngine _engine = new();
    private readonly UpdateService _updater = new();
    private readonly DispatcherTimer _timer = new() { Interval = TimeSpan.FromMilliseconds(100) };
    private AppSettings _settings = new();
    private PhysicalInputMonitor? _input;
    private Forms.NotifyIcon? _tray;
    private ClickProfile Current => _settings.Profiles.First(p => p.Id == _settings.SelectedProfileId);
    private bool _loading = true;
    private bool _armed;
    private bool _heldArmed;
    private nint _targetWindow;
    private string? _capturing; // "activation" or "emergency"
    private bool _checkingUpdate;

    public MainWindow()
    {
        InitializeComponent();
        _timer.Tick += Timer_Tick;
    }

    private void Window_Loaded(object sender, RoutedEventArgs e)
    {
        try
        {
            _settings = _store.Load();
            if (!_settings.Profiles.Any(p => p.Id == _settings.SelectedProfileId))
                _settings.SelectedProfileId = _settings.Profiles[0].Id;
            ProfilesBox.ItemsSource = _settings.Profiles;
            PopulateProfile();
            _input = new PhysicalInputMonitor();
            _input.Changed += Input_Changed;
            InitializeTray();
            _timer.Start();
            SetMessage("Prêt. Passe dans l'application cible puis active le raccourci.");
            if (_settings.AutoUpdate) _ = CheckUpdatesAsync(false);
        }
        catch (Exception ex)
        {
            System.Windows.MessageBox.Show($"ClickFlow n'a pas pu démarrer : {ex.Message}", "ClickFlow", MessageBoxButton.OK, MessageBoxImage.Error);
            Close();
        }
    }

    private void InitializeTray()
    {
        _tray = new Forms.NotifyIcon
        {
            Text = "ClickFlow - AutoClicker",
            Icon = System.Drawing.SystemIcons.Application,
            Visible = true
        };
        var menu = new Forms.ContextMenuStrip();
        menu.Items.Add("Ouvrir ClickFlow", null, (_, _) => Dispatcher.Invoke(RestoreWindow));
        menu.Items.Add("Arrêt d'urgence", null, (_, _) => Dispatcher.Invoke(() => StopAll("Arrêt manuel.")));
        menu.Items.Add("Quitter", null, (_, _) => Dispatcher.Invoke(Close));
        _tray.ContextMenuStrip = menu;
        _tray.DoubleClick += (_, _) => Dispatcher.Invoke(RestoreWindow);
    }

    private void RestoreWindow()
    {
        Show();
        WindowState = WindowState.Normal;
        Activate();
    }

    private void Window_StateChanged(object sender, EventArgs e)
    {
        if (WindowState == WindowState.Minimized && _tray is not null) Hide();
    }

    private void Window_Closing(object? sender, CancelEventArgs e)
    {
        _timer.Stop();
        StopAll("Arrêt.");
        _input?.Dispose();
        _engine.Dispose();
        if (_tray is not null)
        {
            _tray.Visible = false;
            _tray.Dispose();
        }
        Save();
    }

    private void PopulateProfile()
    {
        _loading = true;
        var p = Current;
        ProfilesBox.SelectedItem = p;
        ProfileNameText.Text = p.Name;
        CpsModeBox.SelectedIndex = (int)p.CpsMode;
        VariationBox.SelectedIndex = (int)p.Variation;
        ActivationBox.SelectedIndex = (int)p.ActivationMode;
        TriggerBox.SelectedIndex = (int)p.TriggerMode;
        GateMouseBox.SelectedIndex = Math.Max(0, Array.IndexOf(GateKeys, p.GateMouseKey));
        ClickButtonBox.SelectedIndex = (int)p.ClickButton;
        FocusLossCheck.IsChecked = p.StopOnFocusLoss;
        AutoUpdateCheck.IsChecked = _settings.AutoUpdate;
        ActivationKeyButton.Content = $"Définir la touche : {KeyName(p.ActivationKey)}";
        EmergencyButton.Content = $"Définir la touche : {KeyName(_settings.EmergencyKey)}";
        SyncCpsControls();
        UpdateModeUi();
        _loading = false;
    }

    private void SyncCpsControls()
    {
        var old = _loading;
        _loading = true;
        var p = Current;
        MinCpsSlider.Value = p.MinCps;
        MaxCpsSlider.Value = p.MaxCps;
        if (!MinCpsText.IsKeyboardFocused) MinCpsText.Text = FormatCps(p.MinCps);
        if (!MaxCpsText.IsKeyboardFocused) MaxCpsText.Text = FormatCps(p.MaxCps);
        _loading = old;
    }

    private static string FormatCps(double cps) => cps.ToString("0.##", CultureInfo.CurrentCulture);

    private void UpdateModeUi()
    {
        var fixedMode = Current.CpsMode == CpsMode.Fixed;
        MinimumLabel.Text = fixedMode ? "CPS" : "Minimum CPS";
        MaxCpsSlider.IsEnabled = !fixedMode;
        MaxCpsText.IsEnabled = !fixedMode;
        VariationBox.IsEnabled = Current.CpsMode == CpsMode.Natural;
        VariationLabel.Opacity = Current.CpsMode == CpsMode.Natural ? 1 : .45;
        GatePanel.Visibility = Current.TriggerMode == TriggerMode.MouseHeld ? Visibility.Visible : Visibility.Collapsed;
    }

    private void Configuration_Changed(object sender, SelectionChangedEventArgs e)
    {
        if (_loading || CpsModeBox.SelectedIndex < 0 || ActivationBox.SelectedIndex < 0 ||
            TriggerBox.SelectedIndex < 0 || VariationBox.SelectedIndex < 0 ||
            ClickButtonBox.SelectedIndex < 0 || GateMouseBox.SelectedIndex < 0) return;

        StopAll("Configuration mise à jour.");
        var p = Current;
        p.CpsMode = (CpsMode)CpsModeBox.SelectedIndex;
        p.Variation = (VariationLevel)VariationBox.SelectedIndex;
        p.ActivationMode = (ActivationMode)ActivationBox.SelectedIndex;
        p.TriggerMode = (TriggerMode)TriggerBox.SelectedIndex;
        p.ClickButton = (MouseButtonKind)ClickButtonBox.SelectedIndex;
        p.GateMouseKey = GateKeys[GateMouseBox.SelectedIndex];
        UpdateModeUi();
        Save();
    }

    private void MinCpsSlider_Changed(object sender, RoutedPropertyChangedEventArgs<double> e)
    {
        if (_loading) return;
        ChangeCps(Math.Round(e.NewValue, 1), null);
    }

    private void MaxCpsSlider_Changed(object sender, RoutedPropertyChangedEventArgs<double> e)
    {
        if (_loading) return;
        ChangeCps(null, Math.Round(e.NewValue, 1));
    }

    private void MinCpsText_Changed(object sender, TextChangedEventArgs e)
    {
        if (_loading || !TryReadCps(MinCpsText.Text, out var cps)) return;
        ChangeCps(cps, null);
    }

    private void MaxCpsText_Changed(object sender, TextChangedEventArgs e)
    {
        if (_loading || !TryReadCps(MaxCpsText.Text, out var cps)) return;
        ChangeCps(null, cps);
    }

    private static bool TryReadCps(string raw, out double cps)
    {
        if (!(double.TryParse(raw, NumberStyles.Float, CultureInfo.CurrentCulture, out cps) ||
              double.TryParse(raw, NumberStyles.Float, CultureInfo.InvariantCulture, out cps))) return false;
        return double.IsFinite(cps) && cps >= 1 && cps <= 100;
    }

    private void ChangeCps(double? minimum, double? maximum)
    {
        StopAll("Vitesse mise à jour.");
        var p = Current;
        if (minimum.HasValue)
        {
            p.MinCps = minimum.Value;
            p.MaxCps = Math.Max(p.MaxCps, p.MinCps);
        }
        if (maximum.HasValue)
        {
            p.MaxCps = maximum.Value;
            p.MinCps = Math.Min(p.MinCps, p.MaxCps);
        }
        SyncCpsControls();
        Save();
    }

    private void CpsText_LostFocus(object sender, RoutedEventArgs e) => SyncCpsControls();

    private void ProfilesBox_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_loading || ProfilesBox.SelectedItem is not ClickProfile p) return;
        StopAll("Profil changé.");
        _settings.SelectedProfileId = p.Id;
        PopulateProfile();
        Save();
    }

    private void ProfileName_Changed(object sender, TextChangedEventArgs e)
    {
        if (_loading) return;
        var name = ProfileNameText.Text.Trim();
        if (name.Length is < 1 or > 50) return;
        Current.Name = name;
        var selected = Current;
        _loading = true;
        ProfilesBox.Items.Refresh();
        ProfilesBox.SelectedItem = selected;
        _loading = false;
        Save();
    }

    private void ProfileName_LostFocus(object sender, RoutedEventArgs e)
    {
        if (string.IsNullOrWhiteSpace(ProfileNameText.Text)) ProfileNameText.Text = Current.Name;
    }

    private void NewProfile_Click(object sender, RoutedEventArgs e) => AddProfile(new ClickProfile { Name = NextProfileName() });

    private void DuplicateProfile_Click(object sender, RoutedEventArgs e) =>
        AddProfile(Current.Clone(Current.Name + " (copie)"));

    private string NextProfileName()
    {
        var n = 1;
        while (_settings.Profiles.Any(p => p.Name == $"Profil {n}")) n++;
        return $"Profil {n}";
    }

    private void AddProfile(ClickProfile p)
    {
        StopAll("Nouveau profil.");
        _settings.Profiles.Add(p);
        _settings.SelectedProfileId = p.Id;
        _loading = true;
        ProfilesBox.Items.Refresh();
        _loading = false;
        PopulateProfile();
        Save();
    }

    private void DeleteProfile_Click(object sender, RoutedEventArgs e)
    {
        if (_settings.Profiles.Count == 1)
        {
            System.Windows.MessageBox.Show("Le dernier profil ne peut pas être supprimé.", "ClickFlow");
            return;
        }
        if (System.Windows.MessageBox.Show($"Supprimer le profil '{Current.Name}' ?", "ClickFlow",
                MessageBoxButton.YesNo, MessageBoxImage.Question) != MessageBoxResult.Yes) return;
        StopAll("Profil supprimé.");
        _settings.Profiles.Remove(Current);
        _settings.SelectedProfileId = _settings.Profiles[0].Id;
        _loading = true;
        ProfilesBox.Items.Refresh();
        _loading = false;
        PopulateProfile();
        Save();
    }

    private void FocusLoss_Changed(object sender, RoutedEventArgs e)
    {
        if (_loading) return;
        Current.StopOnFocusLoss = FocusLossCheck.IsChecked == true;
        Save();
    }

    private void AutoUpdate_Changed(object sender, RoutedEventArgs e)
    {
        if (_loading) return;
        _settings.AutoUpdate = AutoUpdateCheck.IsChecked == true;
        Save();
        if (_settings.AutoUpdate) _ = CheckUpdatesAsync(false);
    }

    private void ActivationKeyButton_Click(object sender, RoutedEventArgs e) => BeginCapture("activation");
    private void EmergencyButton_Click(object sender, RoutedEventArgs e) => BeginCapture("emergency");

    private void BeginCapture(string what)
    {
        StopAll("Appuie sur une touche, ou Échap pour annuler.");
        _capturing = what;
        if (what == "activation") ActivationKeyButton.Content = "Appuie sur une touche...";
        else EmergencyButton.Content = "Appuie sur une touche...";
    }

    private void Input_Changed(int key, bool pressed)
    {
        if (_capturing is not null)
        {
            if (!pressed) return;
            var what = _capturing;
            _capturing = null;
            if (key == 0x1B) // Escape cancels capture.
            {
                PopulateProfile();
                SetMessage("Capture annulée.");
                return;
            }
            if ((what == "activation" && key == _settings.EmergencyKey) ||
                (what == "emergency" && key == Current.ActivationKey))
            {
                PopulateProfile();
                SetMessage("La touche d'activation et l'arrêt d'urgence doivent être différents.");
                return;
            }
            if (what == "activation") Current.ActivationKey = key;
            else _settings.EmergencyKey = key;
            PopulateProfile();
            Save();
            SetMessage($"Raccourci enregistré : {KeyName(key)}.");
            return;
        }

        if (key == _settings.EmergencyKey && pressed)
        {
            StopAll("Arrêt d'urgence.");
            return;
        }

        var p = Current;
        if (key == p.ActivationKey)
        {
            if (p.ActivationMode == ActivationMode.Toggle)
            {
                if (pressed)
                {
                    _armed = !_armed;
                    if (!_armed) _targetWindow = 0;
                }
            }
            else
            {
                _heldArmed = pressed;
            }
        }
        if (key == p.ActivationKey || (p.TriggerMode == TriggerMode.MouseHeld && key == p.GateMouseKey))
            Reconcile();
    }

    private void Reconcile()
    {
        var p = Current;
        var active = p.ActivationMode == ActivationMode.Toggle ? _armed : _heldArmed;
        var gate = p.TriggerMode == TriggerMode.Direct || _input?.IsPressed(p.GateMouseKey) == true;
        if (!active || !gate)
        {
            _engine.Stop();
            RefreshStatus();
            return;
        }

        var foreground = Win32.GetForegroundWindow();
        if (_targetWindow != 0 && p.StopOnFocusLoss && foreground != _targetWindow)
        {
            StopAll("Changement de fenêtre : arrêt automatique.");
            return;
        }

        // Prevent generated clicks from pressing buttons in ClickFlow itself.
        if (foreground == new WindowInteropHelper(this).Handle)
        {
            StopAll("Passe dans l'application cible pour activer les clics.");
            return;
        }

        if (_targetWindow == 0) _targetWindow = foreground;
        if (!_engine.IsRunning) _engine.Start(p);
        RefreshStatus();
    }

    private void Timer_Tick(object? sender, EventArgs e)
    {
        if (_targetWindow != 0 && Current.StopOnFocusLoss &&
            Win32.GetForegroundWindow() != _targetWindow)
        {
            StopAll("Changement de fenêtre : arrêt automatique.");
        }
        if (_engine.HasInjectionError)
            StopAll("Windows a refusé les clics simulés pour cette application.");
        RealCpsText.Text = _engine.CurrentCps.ToString(CultureInfo.CurrentCulture);
        TotalClicksText.Text = _engine.TotalClicks.ToString("N0", CultureInfo.CurrentCulture);
        RefreshStatus();
    }

    private void RefreshStatus()
    {
        var on = _engine.IsRunning;
        var waiting = !on && (_armed || _heldArmed);
        StatusBadge.Text = on ? "ACTIF" : waiting ? "ARMÉ" : "INACTIF";
        StatusDot.Fill = new SolidColorBrush(on ? System.Windows.Media.Color.FromRgb(75, 214, 147) :
            waiting ? System.Windows.Media.Color.FromRgb(255, 195, 86) : System.Windows.Media.Color.FromRgb(141, 161, 191));
    }

    private void StopAll(string message)
    {
        _engine.Stop();
        _armed = false;
        _heldArmed = false;
        _targetWindow = 0;
        SetMessage(message);
        RefreshStatus();
    }

    private void Stop_Click(object sender, RoutedEventArgs e) => StopAll("Arrêt manuel.");

    private void SetMessage(string message) => FooterStatusText.Text = message;

    private void Save()
    {
        if (_loading) return;
        try { _store.Save(_settings); }
        catch (IOException) { SetMessage("Impossible de sauvegarder les paramètres sur ce disque."); }
        catch (UnauthorizedAccessException) { SetMessage("Accès refusé au fichier de paramètres."); }
    }

    private static string KeyName(int key) => key switch
    {
        Win32.VkLeft => "Clic gauche",
        Win32.VkRight => "Clic droit",
        Win32.VkMiddle => "Clic central",
        Win32.VkX1 => "Mouse 4",
        Win32.VkX2 => "Mouse 5",
        0x1B => "Échap",
        0x20 => "Espace",
        _ => KeyInterop.KeyFromVirtualKey(key) is Key.None ? $"VK {key:X2}" :
             KeyInterop.KeyFromVirtualKey(key).ToString()
    };

    private async void CheckUpdates_Click(object sender, RoutedEventArgs e) => await CheckUpdatesAsync(true);

    private async Task CheckUpdatesAsync(bool interactive)
    {
        if (_checkingUpdate) return;
        _checkingUpdate = true;
        UpdateStatusText.Text = "Recherche de mises à jour...";
        try
        {
            var (update, message) = await _updater.CheckAsync();
            UpdateStatusText.Text = message;
            if (update is null) return;
            if (interactive)
            {
                if (System.Windows.MessageBox.Show(
                    $"{message}\n\nTélécharger, installer et redémarrer ClickFlow ?",
                    "Mise à jour ClickFlow", MessageBoxButton.YesNo, MessageBoxImage.Question) != MessageBoxResult.Yes)
                    return;
                StopAll("Installation de la mise à jour...");
                Save();
                UpdateStatusText.Text = "Téléchargement en cours...";
                await _updater.DownloadAndRestartAsync(update);
            }
            else
            {
                await _updater.DownloadOnlyAsync(update);
                UpdateStatusText.Text = "Mise à jour téléchargée. Installation au prochain démarrage.";
            }
        }
        catch (Exception ex)
        {
            UpdateStatusText.Text = $"Mise à jour indisponible : {ex.Message}";
        }
        finally { _checkingUpdate = false; }
    }
}
