defmodule KVX.ConflictError do
  defexception [:message]

  def exception(opts) do
    key = Keyword.fetch!(opts, :key)
    val = Keyword.fetch!(opts, :value)

    msg = """
    Expected non-existing slot but got #{key} => #{val}.
    """

    %__MODULE__{message: msg}
  end
end
