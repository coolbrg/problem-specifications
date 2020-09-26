import algorithm, json, os, sequtils, tables, uuids

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
  for testCase in canonicalData.testCases:
    let fields = testCase.getFields()

    for key, _ in fields:
      testCase.delete(key)

    # TODO: use correct sorting
    for key in toSeq(fields.keys).sorted:
      testCase[key] = fields[key]

when isMainModule:
  for canonicalData in walkCanonicalData():
    canonicalData.addUUids()
    canonicalData.orderFields()
    canonicalData.writeFile()
