import std.file;
import std.regex;
import std.variant;
import std.sumtype;
import std.conv;
import std.stdio;
import std.path;
import std.string;
import std.exception;
import std.algorithm;
import std.array;

string readFileContent(string filePath)
{
  enforce(filePath.exists, "File not found: " ~ filePath);

  return readText(filePath);
}

unittest
{
  assertThrown!Exception(readFileContent(`\\`));
  assertNotThrown!Exception(readFileContent(getcwd() ~ "/basic.ini"));
}

alias ScalarSum = SumType!(string, int, double, bool, Scalar[]);

struct Scalar {
    ScalarSum value;

    this(string v) { value = v; }
    this(int v)    { value = v; }
    this(double v) { value = v; }
    this(bool v)   { value = v; }
    this(Scalar[] v) { value = v; }

    alias value this;
}

Scalar parseScalar(string input) {
    try return Scalar(to!bool(input)); catch (ConvException) {}
    try return Scalar(to!int(input)); catch (ConvException) {}
    try return Scalar(to!double(input)); catch (ConvException) {}

    if (!matchFirst(input, ",").empty) {
        auto parts = input.split(",").map!(s => parseScalar(strip(s))).array;
        return Scalar(parts);
    }

    return Scalar(input);
}

Scalar[string] parseIniString(string input)
{
  Scalar[string] result;

  foreach(line; splitLines(input))
  {
    string[] split = line.split("=");
    string key = split[0].strip;
    string value = split[1].strip;
    result[key] = parseScalar(value);
  }

  return result;
}

void main()
{
  string basicIniPath = getcwd() ~ "/basic.ini";
  string basicIniContent = readFileContent(basicIniPath);
  Scalar[string] basicIniResult = parseIniString(basicIniContent);

  enforce(basicIniResult["firstname"].get!string == "brian");
  enforce(basicIniResult["lastname"].get!string == "douglas");
  enforce(basicIniResult["age"].get!int == 33);
}
