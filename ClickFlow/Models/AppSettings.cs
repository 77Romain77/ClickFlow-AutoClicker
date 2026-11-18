namespace ClickFlow.Models;

public sealed class AppSettings
{
    public List<ClickProfile> Profiles { get; set; } = new() { new ClickProfile() };
    public Guid SelectedProfileId { get; set; }
    public int EmergencyKey { get; set; } = 0x7B; // F12
    public bool AutoUpdate { get; set; } = true;
}
