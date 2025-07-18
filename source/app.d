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

alias IniValueMap = IniValue[string];
alias IniValueSum = SumType!(string, int, double, bool, IniValue[], IniValueMap);

struct IniValue {
    IniValueSum value;

    this(string v) { value = v; }
    this(int v)    { value = v; }
    this(double v) { value = v; }
    this(bool v)   { value = v; }
    this(IniValue[] v) { value = v; }
    this(IniValueMap v) { value = v; }

    alias value this;
}

IniValue parseIniValue(string input) {
    try return IniValue(to!bool(input)); catch (ConvException) {}
    try return IniValue(to!int(input)); catch (ConvException) {}
    try return IniValue(to!double(input)); catch (ConvException) {}

    if (!matchFirst(input, ",").empty) {
        auto parts = input.split(",").map!(s => parseIniValue(strip(s))).array;
        return IniValue(parts);
    }

    return IniValue(input);
}

IniValueMap parseIniString(string input)
{
  IniValueMap result;
  string sectionName;

  foreach(line; splitLines(input))
  {
    if(!line.strip.length) continue;
    if(matchFirst(line, "=").empty) {
      if(startsWith(line, "[") && endsWith(line, "]")) {
        auto re = regex(r"\[|\]");
        sectionName = replaceAll(line, re, "");
        IniValueMap section;
        result[sectionName] = IniValue(section);
      }
      continue;
    }

    string[] split = line.split("=");
    string key = split[0].strip;
    auto value = parseIniValue(split[1 .. $].join("").strip);
    if(sectionName) result[sectionName].get!(IniValueMap)[key] = value;
    else result[key] = value;
  }

  return result;
}

unittest
{
  //////////////////////////////////////////////////////////
  // basic values
  //////////////////////////////////////////////////////////
  string basicIniPath = getcwd() ~ "/basic.ini";
  string basicIniContent = readFileContent(basicIniPath);
  IniValueMap basicIniResult = parseIniString(basicIniContent);

  assert(basicIniResult["firstname"].get!string == "brian");
  assert(basicIniResult["lastname"].get!string == "douglas");
  assert(basicIniResult["age"].get!int == 33);

  //////////////////////////////////////////////////////////
  // section values
  //////////////////////////////////////////////////////////
  string sectionIniPath = getcwd() ~ "/sections.ini";
  string sectionIniContent = readFileContent(sectionIniPath);
  IniValueMap sectionIniResult = parseIniString(sectionIniContent);

  assert(sectionIniResult["name"].get!string == "Brian Douglas");
  auto address = sectionIniResult["address"].get!(IniValueMap);
  assert(address["county"].get!string == "Donegal");
  auto pets = sectionIniResult["pets"].get!(IniValueMap);
  assert(pets["dogs"].get!int == 2);
  assert(pets["cats"].get!int == 2);

  //////////////////////////////////////////////////////////
  // arrays values
  //////////////////////////////////////////////////////////
  string arrayValuesIniPath = getcwd() ~ "/array_values.ini";
  string arrayValuesIniContent = readFileContent(arrayValuesIniPath);
  IniValueMap arrayValuesIniResult = parseIniString(arrayValuesIniContent);

  int[] a1 = arrayValuesIniResult["int_array"].get!(IniValue[]).map!(it => it.get!int).array;
  assert(equal(a1, [1, 2, 3, 4, 5]));
  double[] a2 = arrayValuesIniResult["double_array"].get!(IniValue[]).map!(it => it.get!double).array;
  assert(equal(a2, [1.1, 2.2, 3.3, 4.4, 5.5]));
  bool[] a3 = arrayValuesIniResult["bool_array"].get!(IniValue[]).map!(it => it.get!bool).array;
  assert(equal(a3, [true, false, true, false]));
  string[] a4 = arrayValuesIniResult["string_array"].get!(IniValue[]).map!(it => it.get!string).array;
  assert(equal(a4, ["d", "o", "u", "g", "l", "a", "s"]));
  IniValue[] a5 = arrayValuesIniResult["mixed_array"].get!(IniValue[]);
  assert(a5[0].get!string == "brian");
  assert(a5[1].get!string == "douglas");
  assert(a5[2].get!int == 33);
  assert(a5[3].get!bool == true);
  assert(a5[4].get!double == 12.6);
}

void main() {}
