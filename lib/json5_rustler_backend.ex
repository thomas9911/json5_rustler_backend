defmodule Json5RustlerBackend do
  use Rustler, otp_app: :json5_rustler_backend, crate: "json5_rustler_backend"

  # When your NIF is loaded, it will override this function.
  def parse(_term, _config), do: :erlang.nif_error(:nif_not_loaded)
  def make_decimal(_input), do: :erlang.nif_error(:nif_not_loaded)
end
