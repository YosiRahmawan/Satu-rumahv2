import 'api_client.dart';

enum LoadState { idle, loading, loaded, failed }

/// Status pemuatan daftar dari server, agar layar bisa membedakan "sedang
/// memuat", "memang kosong", dan "gagal memuat".
class RemoteLoad {
  const RemoteLoad(this.state, [this.error]);

  static const idle = RemoteLoad(LoadState.idle);
  static const loading = RemoteLoad(LoadState.loading);
  static const loaded = RemoteLoad(LoadState.loaded);

  final LoadState state;
  final ApiException? error;

  bool get isLoading => state == LoadState.loading;
  bool get isFailed => state == LoadState.failed;
}
