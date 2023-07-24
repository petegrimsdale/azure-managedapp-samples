#!/usr/bin/env python3

import json
from pathlib import Path
import os
import sys

mainTemplatePath = Path(
    os.environ.get("MAIN_TEMPLATE_PATH", "templates/managed-storage/main.json")
)
uiTemplatePath = Path(
    os.environ.get("UI_TEMPLATE_PATH", "templates/managed-storage/createUiDefinition.json")
)

print("Reading main template file at '%s'" % (mainTemplatePath,))
mainTemplate = open(mainTemplatePath)

print("Reading UI template file at '%s'" % (uiTemplatePath,))
uiTemplate = open(uiTemplatePath)

mainData = json.load(mainTemplate)
uiData = json.load(uiTemplate)

mainParameters = mainData["parameters"].items()
# filter out parameters with default values
requiredMainParameters = filter(
    lambda x: x[1].get("defaultValue") == None, mainParameters
)

mainParametersKeys = set(map(lambda x: x[0], mainParameters))
requiredMainParametersKeys = set(map(lambda x: x[0], requiredMainParameters))
optionalMainParametersKey = mainParametersKeys - requiredMainParametersKeys

if "uiFormDefinition" in uiData["$schema"]:
    uiParametersKeys = uiData["view"]["outputs"]["parameters"].keys()
elif "CreateUIDefinition.MultiVm" in uiData["$schema"]:
    uiParametersKeys = uiData["parameters"]["outputs"].keys()
else:
    print("Unknown UI template schema")
    sys.exit(2)

print()
print("Common parameters:")
print(json.dumps(sorted(mainParametersKeys & uiParametersKeys), indent=4))
print()
print("Missing required parameters from the UI:")
print(json.dumps(sorted(requiredMainParametersKeys - uiParametersKeys), indent=4))
print()
print("Missing optional parameters from the UI:")
print(json.dumps(sorted(optionalMainParametersKey - uiParametersKeys), indent=4))
print()
print("Unused parameters on the UI:")
print(json.dumps(sorted(uiParametersKeys - mainParametersKeys), indent=4))
print()

if len(requiredMainParametersKeys - uiParametersKeys) == 0:
    print("✅ Parameters match")
    sys.exit(0)
else:
    print("❌ Parameters DO NOT match")
    sys.exit(1)
