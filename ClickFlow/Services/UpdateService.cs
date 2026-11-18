using Velopack;
using Velopack.Sources;

namespace ClickFlow.Services;

public sealed class UpdateService
{
    private readonly UpdateManager _manager = new(new GithubSource(
        "https://github.com/77Romain77/ClickFlow-AutoClicker", null, false));

    public async Task<(UpdateInfo? Update, string Message)> CheckAsync()
    {
        try
        {
            var update = await _manager.CheckForUpdatesAsync();
            return update is null
                ? (null, "ClickFlow est à jour.")
                : (update, $"Nouvelle version : {update.TargetFullRelease.Version}");
        }
        catch (Exception ex) when (ex.GetType().Name == "NotInstalledException")
        {
            return (null, "Mises à jour automatiques disponibles avec la version installée.");
        }
    }

    public Task DownloadOnlyAsync(UpdateInfo update) => _manager.DownloadUpdatesAsync(update);

    public async Task DownloadAndRestartAsync(UpdateInfo update)
    {
        await _manager.DownloadUpdatesAsync(update);
        _manager.ApplyUpdatesAndRestart(update.TargetFullRelease);
    }
}
