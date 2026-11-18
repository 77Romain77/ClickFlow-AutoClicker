using System.Collections.Concurrent;
using System.Diagnostics;
using System.Runtime.InteropServices;
using ClickFlow.Models;
using ClickFlow.Native;

namespace ClickFlow.Services;

public sealed class ClickEngine : IDisposable
{
    private readonly object _gate = new();
    private CancellationTokenSource? _cancellation;
    private long _generation;
    private readonly ConcurrentQueue<long> _recentClicks = new();
    private long _totalClicks;
    private int _running;
    private int _faulted;

    public bool IsRunning => Volatile.Read(ref _running) != 0;
    public bool HasInjectionError => Volatile.Read(ref _faulted) != 0;
    public long TotalClicks => Interlocked.Read(ref _totalClicks);

    public int CurrentCps
    {
        get
        {
            var cutoff = Stopwatch.GetTimestamp() - Stopwatch.Frequency;
            while (_recentClicks.TryPeek(out var tick) && tick < cutoff)
                _recentClicks.TryDequeue(out _);
            return _recentClicks.Count;
        }
    }

    public void Start(ClickProfile profile)
    {
        lock (_gate)
        {
            if (IsRunning) return;
            var source = new CancellationTokenSource();
            _cancellation = source;
            var generation = ++_generation;
            Volatile.Write(ref _faulted, 0);
            Volatile.Write(ref _running, 1);
            _ = Task.Run(() => RunAsync(profile.Clone(profile.Name), source, generation), source.Token);
        }
    }

    public void Stop()
    {
        lock (_gate)
        {
            ++_generation;
            Volatile.Write(ref _running, 0);
            _cancellation?.Cancel();
            _cancellation = null;
        }
    }

    private async Task RunAsync(ClickProfile profile, CancellationTokenSource source, long generation)
    {
        var token = source.Token;
        var start = Stopwatch.GetTimestamp();
        var nextTick = start;
        var naturalCps = (profile.MinCps + profile.MaxCps) / 2;
        var targetCps = naturalCps;
        var nextTargetTime = start;
        try
        {
            while (!token.IsCancellationRequested)
            {
                var now = Stopwatch.GetTimestamp();
                if (nextTick > now)
                {
                    var remainingMs = (nextTick - now) * 1000.0 / Stopwatch.Frequency;
                    if (remainingMs >= 2)
                        await Task.Delay(TimeSpan.FromMilliseconds(Math.Max(1, remainingMs - 1)), token).ConfigureAwait(false);
                    else
                        Thread.SpinWait(100);
                    continue;
                }

                if (!IsRunning) break;
                if (!InjectClick(profile.ClickButton))
                {
                    Volatile.Write(ref _faulted, 1);
                    break;
                }

                Interlocked.Increment(ref _totalClicks);
                _recentClicks.Enqueue(Stopwatch.GetTimestamp());

                double cps;
                switch (profile.CpsMode)
                {
                    case CpsMode.Fixed:
                        cps = profile.MinCps;
                        break;
                    case CpsMode.Random:
                        cps = Between(profile.MinCps, profile.MaxCps);
                        break;
                    default:
                        var clock = Stopwatch.GetTimestamp();
                        if (clock >= nextTargetTime)
                        {
                            targetCps = Between(profile.MinCps, profile.MaxCps);
                            nextTargetTime = clock + (long)(Between(.18, .55) * Stopwatch.Frequency);
                        }
                        var speed = profile.Variation switch
                        {
                            VariationLevel.Low => .045,
                            VariationLevel.Medium => .12,
                            _ => .28
                        };
                        naturalCps += (targetCps - naturalCps) * speed;
                        var jitter = profile.Variation switch
                        {
                            VariationLevel.Low => .01,
                            VariationLevel.Medium => .03,
                            _ => .07
                        };
                        cps = Math.Clamp(naturalCps + Between(-jitter, jitter) * (profile.MaxCps - profile.MinCps),
                            profile.MinCps, profile.MaxCps);
                        break;
                }

                var intervalTicks = (long)(Stopwatch.Frequency / Math.Max(1, cps));
                nextTick += intervalTicks;
                // Avoid a catch-up burst if Windows stalls scheduling for a while.
                var current = Stopwatch.GetTimestamp();
                if (nextTick < current) nextTick = current + intervalTicks;
            }
        }
        catch (OperationCanceledException) { }
        finally
        {
            lock (_gate)
            {
                if (_generation == generation)
                {
                    Volatile.Write(ref _running, 0);
                    _cancellation = null;
                }
                source.Dispose();
            }
        }
    }

    private static double Between(double min, double max) => min + Random.Shared.NextDouble() * (max - min);

    private static bool InjectClick(MouseButtonKind button)
    {
        var (down, up) = button switch
        {
            MouseButtonKind.Right => (Win32.MouseRightDown, Win32.MouseRightUp),
            MouseButtonKind.Middle => (Win32.MouseMiddleDown, Win32.MouseMiddleUp),
            _ => (Win32.MouseLeftDown, Win32.MouseLeftUp)
        };
        var events = new[]
        {
            new Win32.Input { Type = Win32.InputMouse, Mouse = new Win32.MouseInput { Flags = down } },
            new Win32.Input { Type = Win32.InputMouse, Mouse = new Win32.MouseInput { Flags = up } }
        };
        return Win32.SendInput(2, events, Marshal.SizeOf<Win32.Input>()) == 2;
    }

    public void Dispose() => Stop();
}
