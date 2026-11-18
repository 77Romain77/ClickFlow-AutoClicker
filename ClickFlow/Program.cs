using System;
using System.Threading;
using Velopack;

namespace ClickFlow;

internal static class Program
{
    [STAThread]
    private static void Main()
    {
        VelopackApp.Build().SetAutoApplyOnStartup(true).Run();

        using var mutex = new Mutex(true, @"Local\ClickFlow_AutoClicker_SingleInstance", out var isFirstInstance);
        if (!isFirstInstance)
        {
            System.Windows.MessageBox.Show("ClickFlow est déjà ouvert.", "ClickFlow");
            return;
        }

        var app = new App();
        app.InitializeComponent();
        app.Run();
    }
}
