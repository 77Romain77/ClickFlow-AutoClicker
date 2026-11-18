namespace ClickFlow.Models;

public enum CpsMode { Fixed, Random, Natural }
public enum VariationLevel { Low, Medium, High }
public enum ActivationMode { Hold, Toggle }
public enum TriggerMode { Direct, MouseHeld }
public enum MouseButtonKind { Left, Right, Middle }

public sealed class ClickProfile
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = "Défaut";
    public CpsMode CpsMode { get; set; } = CpsMode.Natural;
    public double MinCps { get; set; } = 8;
    public double MaxCps { get; set; } = 14;
    public VariationLevel Variation { get; set; } = VariationLevel.Medium;
    public ActivationMode ActivationMode { get; set; } = ActivationMode.Hold;
    public TriggerMode TriggerMode { get; set; } = TriggerMode.Direct;
    public int ActivationKey { get; set; } = 0x75; // F6
    public int GateMouseKey { get; set; } = 0x01; // Left mouse
    public MouseButtonKind ClickButton { get; set; } = MouseButtonKind.Left;
    public bool StopOnFocusLoss { get; set; } = true;

    public ClickProfile Clone(string name) => new()
    {
        Name = name,
        CpsMode = CpsMode,
        MinCps = MinCps,
        MaxCps = MaxCps,
        Variation = Variation,
        ActivationMode = ActivationMode,
        TriggerMode = TriggerMode,
        ActivationKey = ActivationKey,
        GateMouseKey = GateMouseKey,
        ClickButton = ClickButton,
        StopOnFocusLoss = StopOnFocusLoss
    };
}
