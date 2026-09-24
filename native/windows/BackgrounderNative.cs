using System.Runtime.InteropServices;
using System.Text.Json;

namespace ChabotBackgrounder;

internal static partial class BackgrounderNative
{
    [LibraryImport("backgrounder_core", EntryPoint = "backgrounder_api_version")]
    internal static partial uint ApiVersion();

    [LibraryImport("backgrounder_core", EntryPoint = "backgrounder_create", StringMarshalling = StringMarshalling.Utf8)]
    internal static partial nint Create(string folder, string ffprobe);

    [LibraryImport("backgrounder_core", EntryPoint = "backgrounder_snapshot")]
    internal static partial nint Snapshot(nint engine);

    [LibraryImport("backgrounder_core", EntryPoint = "backgrounder_build")]
    internal static partial nint Build(nint engine);

    [LibraryImport("backgrounder_core", EntryPoint = "backgrounder_refresh")]
    internal static partial void Refresh(nint engine);

    [LibraryImport("backgrounder_core", EntryPoint = "backgrounder_last_error")]
    internal static partial nint LastError();

    [LibraryImport("backgrounder_core", EntryPoint = "backgrounder_free_string")]
    internal static partial void FreeString(nint value);

    [LibraryImport("backgrounder_core", EntryPoint = "backgrounder_destroy")]
    internal static partial void Destroy(nint engine);

    internal static string TakeString(nint pointer)
    {
        if (pointer == 0) return "Unknown engine error";
        string result = Marshal.PtrToStringUTF8(pointer) ?? "";
        FreeString(pointer);
        return result;
    }
}

internal sealed class EngineHost : IDisposable
{
    private nint handle;

    public EngineHost(string folder)
    {
        if (BackgrounderNative.ApiVersion() != 1) throw new InvalidOperationException("Incompatible Rust engine");
        string probe = Path.Combine(AppContext.BaseDirectory, "ffprobe.exe");
        handle = BackgrounderNative.Create(folder, File.Exists(probe) ? probe : "ffprobe");
        if (handle == 0) throw new InvalidOperationException(BackgrounderNative.TakeString(BackgrounderNative.LastError()));
    }

    public JsonDocument Snapshot() => Parse(BackgrounderNative.Snapshot(handle));
    public JsonDocument Build() => Parse(BackgrounderNative.Build(handle));
    public void Refresh() => BackgrounderNative.Refresh(handle);

    private static JsonDocument Parse(nint pointer)
    {
        if (pointer == 0) throw new InvalidOperationException(BackgrounderNative.TakeString(BackgrounderNative.LastError()));
        return JsonDocument.Parse(BackgrounderNative.TakeString(pointer));
    }

    public void Dispose()
    {
        if (handle != 0) { BackgrounderNative.Destroy(handle); handle = 0; }
    }
}
