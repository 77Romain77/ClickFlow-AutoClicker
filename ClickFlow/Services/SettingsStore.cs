using System.Text.Json;
using ClickFlow.Models;

namespace ClickFlow.Services;

public sealed class SettingsStore
{
    private static readonly JsonSerializerOptions Options = new() { WriteIndented = true };
    public bool IsPortable { get; } = File.Exists(Path.Combine(AppContext.BaseDirectory, "portable.flag"));
    public string SettingsFile { get; }

    public SettingsStore()
    {
        var folder = IsPortable
            ? AppContext.BaseDirectory
            : Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "ClickFlow");
        SettingsFile = Path.Combine(folder, "settings.json");
    }

    public AppSettings Load()
    {
        if (!File.Exists(SettingsFile)) return new AppSettings();
        try
        {
            var settings = JsonSerializer.Deserialize<AppSettings>(File.ReadAllText(SettingsFile), Options) ?? new();
            settings.Profiles ??= new List<ClickProfile>();
            if (settings.Profiles.Count == 0) settings.Profiles.Add(new ClickProfile());
            foreach (var profile in settings.Profiles)
            {
                profile.MinCps = Math.Clamp(profile.MinCps, 1, 100);
                profile.MaxCps = Math.Clamp(profile.MaxCps, profile.MinCps, 100);
                if (string.IsNullOrWhiteSpace(profile.Name)) profile.Name = "Profil";
            }
            return settings;
        }
        catch (JsonException)
        {
            // Do not overwrite a broken settings file before the user can recover it.
            var backup = SettingsFile + ".invalid-" + DateTime.Now.ToString("yyyyMMdd-HHmmss");
            File.Move(SettingsFile, backup, overwrite: true);
            return new AppSettings();
        }
    }

    public void Save(AppSettings settings)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(SettingsFile)!);
        var temp = SettingsFile + ".tmp";
        File.WriteAllText(temp, JsonSerializer.Serialize(settings, Options));
        File.Move(temp, SettingsFile, overwrite: true);
    }
}
