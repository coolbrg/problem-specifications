import json, os, sequtils, strformat, tables, uuids

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

proc testCases(node: JsonNode): seq[JsonNode] =
  for testCase in node["cases"].getElems():
    if testCase.hasKey("cases"):
      result.add(testCase.testCases())
    else:
      result.add(testCase)

proc testCases(canonicalData: CanonicalData): seq[JsonNode] =
  canonicalData.json.testCases()

proc addUUids(canonicalData: CanonicalData): void =
  for testCase in canonicalData.testCases:
    if not testCase.hasKey("uuid"):
      testCase["uuid"] = % $genUUID()

proc orderFields(canonicalData: CanonicalData): void =
  const expectedFieldOrder = ["uuid", "description", "comments", "property", "input", "expected", "scenarios"]

  for testCase in canonicalData.testCases:
    let fields = testCase.getFields()

    for key, _ in fields:
      testCase.delete(key)

    for key in expectedFieldOrder:
      if key in fields:
        testCase[key] = fields[key]

proc verifyFields(canonicalData: CanonicalData): void =
  const requiredFields = ["uuid", "description", "property", "input", "expected"]

  for testCase in canonicalData.testCases:
    for requiredField in requiredFields:
      if requiredField notin toSeq(testCase.keys):
        echo &"Test case is missing required field: {requiredField}"

when isMainModule:
  for canonicalData in walkCanonicalData():
    # canonicalData.addUUids()
    # canonicalData.orderFields()
    # canonicalData.writeFile()
    # canonicalData.verifyFields()
