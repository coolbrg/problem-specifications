import json, os, uuids

type
  CanonicalData = object
    file: string
    json: JsonNode

proc initCanonicalData(file: string): CanonicalData =
  CanonicalData(file: file, json: parseFile(file))

iterator walkCanonicalData: CanonicalData =
  for exerciseDir in walkDirs("exercises/*"):
    let canonicalDataFile = exerciseDir / "canonical-data.json"
    if fileExists(canonicalDataFile):
      try:
        yield initCanonicalData(canonicalDataFile)
      except:
        echo getCurrentExceptionMsg()

proc writeFile(canonicalData: CanonicalData): void =
  writeFile(canonicalData.file, canonicalData.json.pretty() & "\n")

proc format(canonicalData: CanonicalData): void =
  canonicalData.writeFile()

proc testCases(node: JsonNode): seq[JsonNode] =
  for testCase in node["cases"].getElems():
    if testCase.hasKey("cases"):
      result.add(testCase.testCases())
    else:
      result.add(testCase)

proc testCases(canonicalData: CanonicalData): seq[JsonNode] =
  canonicalData.json.testCases()

proc addMissing(canonicalData: CanonicalData): void =
  for testCase in canonicalData.testCases:
    if not testCase.hasKey("uuid"):
      testCase["uuid"] = % $genUUID()

  writeFile(canonicalData.file, canonicalData.json.pretty() & "\n")

when isMainModule:
  for canonicalData in walkCanonicalData():
    canonicalData.addMissing()
