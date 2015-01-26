defmodule Flex.Worker do
  @moduledoc """
  Encapsulates the work that needs to be done on the file system to convert a file from a .flac to a .mp3.
  """

  @sec 1_000

  @doc """
  Given a .flac filename, kick off and wait for System jobs to create a corresponding .mp3 file for the .flac file.
  """
  def convert_flac(flac_filename) do
    {basename, directory_name} = split_filename(flac_filename)
    IO.puts "starting on #{basename}..."
    {wav_filename, mp3_filename} = generate_filenames(directory_name, basename)

    Task.async(fn -> System.cmd("flac", ["--silent", "--force", "--decode", "--output-name", wav_filename, flac_filename], stderr_to_stdout: false) end)
    |> Task.await(10 * @sec)

    Task.async(fn -> System.cmd("lame", ["--silent", "--abr", "320", wav_filename, mp3_filename], stderr_to_stdout: false) end)
    |> Task.await(30 * @sec)

    Task.async(fn -> System.cmd("rm", [wav_filename]) end)
    |> Task.await(1 * @sec)

    IO.puts "...#{basename} done"
  end

  @doc """
  Given a directory name and a file basename, return .mp3 and .wav filenames.

  ## Examples

    iex> Flex.Worker.generate_filenames("/foo/bar", "baz.qux")
    {"/foo/bar/baz.qux.wav", "/foo/bar/baz.qux.mp3"}
  """
  @spec generate_filenames(char_list, char_list) :: {String.t, String.t}
  def generate_filenames(directory_name, basename) do
    wav_filename = Path.join(directory_name, "#{basename}.wav")
    mp3_filename = Path.join(directory_name, "#{basename}.mp3")
    {wav_filename, mp3_filename}
  end

  @doc """
  Given a .flac filename, extract the directory name and the file basename.

  ## Examples

    iex> Flex.Worker.split_filename("/foo/bar/baz.flac")
    {"baz", "/foo/bar"}
  """
  @spec split_filename(char_list) :: {String.t, String.t}
  def split_filename(flac_filename) do
    basename = Path.basename(flac_filename, ".flac")
    directory_name = Path.dirname(flac_filename)
    {basename, directory_name}
  end

end
