#!/usr/bin/env python3
"""Generate Aether.xcodeproj deterministically (no xcodegen needed)."""
import os
import uuid

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "Sources")
PROJ = os.path.join(ROOT, "Aether.xcodeproj")
SWIFTS = sorted(f for f in os.listdir(SRC) if f.endswith(".swift"))


def uid(name: str) -> str:
    return uuid.uuid5(uuid.NAMESPACE_URL, "aether:" + name).hex.upper()[:24]


bids = "".join(f"\t\t{uid('build:' + s)} = {{isa = PBXBuildFile; fileRef = {uid('ref:' + s)}; }};\n" for s in SWIFTS)
refs = "".join(f"\t\t{uid('ref:' + s)} = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {s}; sourceTree = \"<group>\"; }};\n" for s in SWIFTS)
files = "".join(f"\t\t\t\t{uid('build:' + s)},\n" for s in SWIFTS)
children = "".join(f"\t\t\t\t{uid('ref:' + s)},\n" for s in SWIFTS)

MAIN = uid("main"); SRCG = uid("srcg"); PROD = uid("prod"); PROJ_OBJ = uid("proj")
TARG = uid("target"); SRCPH = uid("srcphase"); FWPH = uid("fwphase")
CONF_PROJ = uid("conflist:proj"); CONF_TARG = uid("conflist:targ")
DBG_PROJ = uid("cfg:proj:dbg"); REL_PROJ = uid("cfg:proj:rel")
DBG_TARG = uid("cfg:targ:dbg"); REL_TARG = uid("cfg:targ:rel")
APPREF = uid("ref:app")
PLISTREF = uid("ref:plist")

pbx = """// !$*UTF8*$!
{
\tarchiveVersion = 1;
\tclasses = {
\t};
\tobjectVersion = 56;
\tobjects = {
""" + bids + refs + f"""\t\t{APPREF} = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Aether.app; sourceTree = BUILT_PRODUCTS_DIR; }};
\t\t{PLISTREF} = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};
\t\t{MAIN} = {{isa = PBXGroup; children = ({SRCG}, {PROD}); sourceTree = "<group>"; }};
\t\t{SRCG} = {{isa = PBXGroup; name = Sources; path = Sources; sourceTree = "<group>"; children = (
{children}\t\t\t\t{PLISTREF},
\t\t); }};
\t\t{PROD} = {{isa = PBXGroup; name = Products; sourceTree = "<group>"; children = ({APPREF}); }};
\t\t{TARG} = {{isa = PBXNativeTarget; buildPhases = ({SRCPH}, {FWPH}); buildRules = (); dependencies = (); name = Aether; productName = Aether; productReference = {APPREF}; productType = "com.apple.product-type.application"; }};
\t\t{SRCPH} = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (
{files}\t\t\t); runOnlyForDeploymentPostprocessing = 0; }};
\t\t{FWPH} = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};
\t\t{CONF_PROJ} = {{isa = XCConfigurationList; buildConfigurations = ({DBG_PROJ}, {REL_PROJ}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};
\t\t{CONF_TARG} = {{isa = XCConfigurationList; buildConfigurations = ({DBG_TARG}, {REL_TARG}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};
\t\t{DBG_PROJ} = {{isa = XCBuildConfiguration; buildSettings = {{ALWAYS_SEARCH_USER_PATHS = NO; CLANG_ENABLE_MODULES = YES; SWIFT_VERSION = 6.0; }}; name = Debug; }};
\t\t{REL_PROJ} = {{isa = XCBuildConfiguration; buildSettings = {{ALWAYS_SEARCH_USER_PATHS = NO; CLANG_ENABLE_MODULES = YES; SWIFT_VERSION = 6.0; }}; name = Release; }};
\t\t{DBG_TARG} = {{isa = XCBuildConfiguration; buildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;\n\t\t\t\tINFOPLIST_FILE = Sources/Info.plist;
\t\t\t\tCODE_SIGNING_ALLOWED = NO;
\t\t\t\tCODE_SIGN_IDENTITY = "";
\t\t\t\t
\t\t\t\t
\t\t\t\t
\t\t\t\t
\t\t\t\t
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 26.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = dev.aether.Aether;
\t\t\t\tPRODUCT_NAME = Aether;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t}}; name = Debug; }};
\t\t{REL_TARG} = {{isa = XCBuildConfiguration; buildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;\n\t\t\t\tINFOPLIST_FILE = Sources/Info.plist;
\t\t\t\tCODE_SIGNING_ALLOWED = NO;
\t\t\t\tCODE_SIGN_IDENTITY = "";
\t\t\t\t
\t\t\t\t
\t\t\t\t
\t\t\t\t
\t\t\t\t
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 26.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = dev.aether.Aether;
\t\t\t\tPRODUCT_NAME = Aether;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t}}; name = Release; }};
\t\t{PROJ_OBJ} = {{isa = PBXProject; attributes = {{LastUpgradeCheck = 2600; }}; buildConfigurationList = {CONF_PROJ}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en); mainGroup = {MAIN}; productRefGroup = {PROD}; projectDirPath = ""; targets = ({TARG}); }};
\t}};
\trootObject = {PROJ_OBJ};
}}
"""

os.makedirs(PROJ, exist_ok=True)
with open(os.path.join(PROJ, "project.pbxproj"), "w") as f:
    f.write(pbx)

scheme = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "2600"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES"
      runPostActionsOnFailure = "NO">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{TARG}"
               BuildableName = "Aether.app"
               BlueprintName = "Aether"
               ReferencedContainer = "container:Aether.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      shouldAutocreateTestPlan = "YES">
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""
schemedir = os.path.join(PROJ, "xcshareddata", "xcschemes")
os.makedirs(schemedir, exist_ok=True)
with open(os.path.join(schemedir, "Aether.xcscheme"), "w") as f:
    f.write(scheme)
print(f"wrote {PROJ} with {len(SWIFTS)} sources")
