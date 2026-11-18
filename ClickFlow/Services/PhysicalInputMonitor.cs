using System.ComponentModel;
using System.Runtime.InteropServices;
using ClickFlow.Native;

namespace ClickFlow.Services;

// Low-level hooks let us distinguish physical input from our SendInput events.
// They never block or suppress the input received by other applications.
public sealed class PhysicalInputMonitor : IDisposable
{
    private readonly HashSet<int> _pressed = new();
    private readonly Win32.HookProc _keyboardCallback;
    private readonly Win32.HookProc _mouseCallback;
    private nint _keyboardHook;
    private nint _mouseHook;
    private bool _disposed;

    public event Action<int, bool>? Changed;

    public PhysicalInputMonitor()
    {
        _keyboardCallback = OnKeyboard;
        _mouseCallback = OnMouse;
        var module = Win32.GetModuleHandle(null);
        _keyboardHook = Win32.SetWindowsHookEx(Win32.WhKeyboardLl, _keyboardCallback, module, 0);
        if (_keyboardHook == 0)
            throw new Win32Exception(Marshal.GetLastWin32Error(), "Impossible d'installer le raccourci clavier global.");
        _mouseHook = Win32.SetWindowsHookEx(Win32.WhMouseLl, _mouseCallback, module, 0);
        if (_mouseHook == 0)
        {
            var error = Marshal.GetLastWin32Error();
            Win32.UnhookWindowsHookEx(_keyboardHook);
            _keyboardHook = 0;
            throw new Win32Exception(error, "Impossible d'installer les raccourcis souris.");
        }
    }

    public bool IsPressed(int virtualKey) => _pressed.Contains(virtualKey);

    private nint OnKeyboard(int code, nint wParam, nint lParam)
    {
        if (code >= 0)
        {
            var data = Marshal.PtrToStructure<Win32.KeyboardHookData>(lParam);
            if ((data.Flags & 0x10) == 0) // LLKHF_INJECTED
            {
                var msg = (int)wParam;
                if (msg is Win32.WmKeyDown or Win32.WmSysKeyDown)
                    Update((int)data.VkCode, true);
                else if (msg is Win32.WmKeyUp or Win32.WmSysKeyUp)
                    Update((int)data.VkCode, false);
            }
        }
        return Win32.CallNextHookEx(_keyboardHook, code, wParam, lParam);
    }

    private nint OnMouse(int code, nint wParam, nint lParam)
    {
        if (code >= 0)
        {
            var data = Marshal.PtrToStructure<Win32.MouseHookData>(lParam);
            if ((data.Flags & 1) == 0) // LLMHF_INJECTED
            {
                var msg = (int)wParam;
                var virtualKey = msg switch
                {
                    Win32.WmLeftDown or Win32.WmLeftUp => Win32.VkLeft,
                    Win32.WmRightDown or Win32.WmRightUp => Win32.VkRight,
                    Win32.WmMiddleDown or Win32.WmMiddleUp => Win32.VkMiddle,
                    Win32.WmXDown or Win32.WmXUp => (data.MouseData >> 16) == 1 ? Win32.VkX1 : Win32.VkX2,
                    _ => 0
                };
                if (virtualKey != 0)
                {
                    var down = msg is Win32.WmLeftDown or Win32.WmRightDown or Win32.WmMiddleDown or Win32.WmXDown;
                    Update(virtualKey, down);
                }
            }
        }
        return Win32.CallNextHookEx(_mouseHook, code, wParam, lParam);
    }

    private void Update(int virtualKey, bool down)
    {
        // Key repeat is intentionally ignored, so Toggle switches only once per press.
        if (down ? _pressed.Add(virtualKey) : _pressed.Remove(virtualKey))
            Changed?.Invoke(virtualKey, down);
    }

    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;
        if (_keyboardHook != 0) Win32.UnhookWindowsHookEx(_keyboardHook);
        if (_mouseHook != 0) Win32.UnhookWindowsHookEx(_mouseHook);
        _pressed.Clear();
    }
}
