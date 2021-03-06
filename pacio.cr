lib LibSTDIO
  type File = Void*
  fun fopen(filename : UInt8*, mode : UInt8*) : File
  fun fclose(file : File)
  fun fgets(string : UInt8*, size : Int32, file : File) : UInt8*
  fun fputs(string : UInt8*, file : File)
  fun access(path : UInt8*, mode : Int32) : Int32

  F_OK = 0
end

class PacioException < Exception
end

class Pacio
  def self.open_for_read(filename : String)
    assert_file_exists(filename)
    PacioFile.new(LibSTDIO.fopen(filename, "r"))
  end

  def self.open_for_write(filename : String)
    assert_file_exists(filename)
    PacioFile.new(LibSTDIO.fopen(filename, "w"))
  end

  def self.file_exists?(filename : String)
    LibSTDIO.access(filename, LibSTDIO::F_OK) != -1
  end

  private def self.assert_file_exists(filename)
    unless file_exists?(filename)
      raise PacioException.new("File `#{filename}` does not exist")
    end
  end
end

class PacioFile
  DEFAULT_BUFFER_SIZE = 255

  def initialize(@file : LibSTDIO::File)
    @buffer_size = DEFAULT_BUFFER_SIZE
  end

  def read_line(keep_newline = false)
    line = Slice(UInt8).new(@buffer_size)
    eof = LibSTDIO.fgets(line.pointer(@buffer_size), line.length, @file)
    return nil if eof.nil?

    string = String.build do |builder|
      builder.write(line, line.length)
    end
  
    keep_newline ? string : string[0..-1]
  end

  def read_all
    result = ""
    while(line = read_line(true))
      result += line
    end
    result
  end

  def write_line(value)
    write("#{value}\n")
  end

  def write(value)
    LibSTDIO.fputs(value.to_s, @file)
  end

  def close
    LibSTDIO.fclose(@file)
  end

  # Can be used to adjust the buffer size for reading in lines.
  # Defaults to a relatively low value for performance, but can be increased using this method.
  def buffer_size=(value)
    @buffer_size = value
  end
end
