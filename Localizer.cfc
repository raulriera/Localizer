<cfcomponent output="false">
	
	<cffunction name="init" access="public" output="false" returntype="any">
		<cfset this.version = "0.9.3,1.0,1.1">
		<cfreturn this />
	</cffunction>
	
	<cffunction name="l" returntype="any" output="false" access="public" hint="Shortcut method to 'localize'">
		<cfargument name="text" type="string" required="true" hint="Text to localize" />
		<cfreturn localize(arguments.text) />
	</cffunction>

	<cffunction name="localize" returnType="any" output="false" access="public">
		<cfargument name="text" type="string" required="true" hint="Text to localize" />
		<cfscript>
			var loc = {};
			
			arguments.source = $captureTemplateAndLineNumber();
			
			loc.result = "";
			loc.textContainsDynamicText = (arguments.text CONTAINS "{" AND arguments.text CONTAINS "}");
			// get the text from the repo for the local specified
			loc.localizedText = $getLocalizedText();
			
			if (loc.textContainsDynamicText)
			{
				loc.textBetweenDynamicText = REMatch("{(.*?)}", arguments.text);
				loc.iEnd = ArrayLen(loc.textBetweenDynamicText);
				for (loc.i = 1; loc.i lte loc.iEnd; loc.i++)
					arguments.text = Replace(arguments.text, loc.textBetweenDynamicText[loc.i], "{variable}", "all");
			}
			// Return the localized text in the current locale
			loc.translation = $findLocalizedText(text=arguments.text, struct=loc.localizedText, source=arguments.source);
			if (ListFindNoCase("design,development", get("environment")))
			{
				if (Len(loc.translation))
				{
					loc.result = loc.translation;
				}
				else
				{
					$writeTextIntoLocalizationRepository(text=arguments.text, source=arguments.source);
					loc.result = arguments.text;
				}
			}
			else if (Len(loc.translation))
			{
				loc.result = loc.translation;
			}
			if (loc.textContainsDynamicText)
			{
				// Go through the array and replace the "{variable}" back with the respective values 
				loc.iEnd = ArrayLen(loc.textBetweenDynamicText);
				for (loc.i = 1; loc.i lte loc.iEnd; loc.i++)
					loc.result = Replace(loc.result, "{variable}", loc.textBetweenDynamicText[loc.i]);
				// Remove all "{}"
				loc.result = ReplaceList(loc.result, "{,}", "");
			}
		</cfscript>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="getLocaleCode" returnType="string" hint="Since ColdFusion has several names for locales and not the standard 5 letters code, this function will enforce the return of the locale in the 5 letter code">
		<cfscript>
			var loc = {};
			loc.currentLocale = getLocale();
			// translate coldfusion locales to their corresponding codes
			if (Len(loc.currentLocale) gt 5)
			{
				switch (loc.currentLocale)
				{
					case "Chinese (China)":        { loc.currentLocale = "zh_CN"; break; }
					case "Chinese (Hong Kong)":    { loc.currentLocale = "zh_HK"; break; }
					case "Chinese (Taiwan)":       { loc.currentLocale = "zh_TW"; break; }
					case "Dutch (Belgian)":        { loc.currentLocale = "nl_BE"; break; }
					case "Dutch (Standard)":       { loc.currentLocale = "nl_NL"; break; }
					case "English (Australian)":   { loc.currentLocale = "en_AU"; break; }
					case "English (Canadian)":     { loc.currentLocale = "en_CA"; break; }
					case "English (New Zealand)":  { loc.currentLocale = "en_NZ"; break; }
					case "English (UK)":           { loc.currentLocale = "en_GB"; break; }
					case "English (US)":           { loc.currentLocale = "en_US"; break; }
					case "French (Belgian)":       { loc.currentLocale = "fr_BE"; break; }
					case "French (Canadian)":      { loc.currentLocale = "fr_CA"; break; }
					case "French (Standard)":      { loc.currentLocale = "fr_FR"; break; }
					case "French (Swiss)":         { loc.currentLocale = "fr_CH"; break; }
					case "German (Austrian)":      { loc.currentLocale = "de_AT"; break; }
					case "German (Standard)":      { loc.currentLocale = "de_DE"; break; }
					case "German (Swiss)":         { loc.currentLocale = "de_CH"; break; }
					case "Italian (Standard)":     { loc.currentLocale = "it_IT"; break; }
					case "Italian (Swiss)":        { loc.currentLocale = "it_CH"; break; }
					case "Japanese":               { loc.currentLocale = "ja_JP"; break; }
					case "Korean":                 { loc.currentLocale = "ko_KR"; break; }
					case "Norwegian (Bokmal)":     { loc.currentLocale = "no_NO"; break; }
					case "Norwegian (Nynorsk)":    { loc.currentLocale = "no_NO"; break; }
					case "Portuguese (Brazilian)": { loc.currentLocale = "pt_BR"; break; }
					case "Portuguese (Standard)":  { loc.currentLocale = "pt_PT"; break; }
					case "Spanish (Mexican)":      { loc.currentLocale = "es_MX"; break; }
					case "Spanish (Modern)":       { loc.currentLocale = "es_US"; break; }
					case "Spanish (Standard)":     { loc.currentLocale = "es_ES"; break; }
					case "Swedish":                { loc.currentLocale = "sv_SE"; break; }
				}
			}
		</cfscript>
		<cfreturn loc.currentLocale>
	</cffunction>
	
	<cffunction name="$$populateRepository" returntype="void" output="false" access="public">
		<cfargument name="folderList" type="string" required="false" default="controllers,models,views" />
		<cfscript>
			var loc = {};
			
			if (!ListFindNoCase("design,development", get("environment")))
				$throw(type="Wheels.Localizer.AccessDenied", message="The method `$$populateRepository` may only be run is design or development modes.");
			
			loc.iEnd = ListLen(arguments.folderList);
			for (loc.i = 1; loc.i lte loc.iEnd; loc.i++)
			{
				// get our directory from the list
				loc.relativeDir = ListGetAt(arguments.folderList, loc.i);
				
				// decide how we should filter the files
				if (ListFindNoCase("controllers,models", loc.relativeDir))
					loc.filter = "*.cfc";
				else
					loc.filter = "*.cfm";
				
				loc.files = $directory(action="list", type="file", recurse=true, filter=loc.filter, listInfo="name", directory=ExpandPath(loc.relativeDir));
				loc.xEnd = loc.files.RecordCount;
				for (loc.x = 1; loc.x lte loc.xEnd; loc.x++)
				{
					loc.file = loc.relativeDir & "/" & loc.files.name[loc.x];
					loc.fileReader = CreateObject("java", "java.io.FileReader").init(ExpandPath(loc.file));
					loc.lineReader = CreateObject("java","java.io.LineNumberReader").init(loc.fileReader);
					
					loc.line = loc.lineReader.readLine();  
					loc.lineCount = 1;  
					
					while (StructKeyExists(loc, "line")) 
					{
						loc.matches = REMatch("([^a-zA-Z0-9]l|[^a-zA-Z0-9]localize)[[:space:]]?(\([[:space:]]?['""](.*?)['""][[:space:]]?)\)", loc.line);
						loc.mEnd = ArrayLen(loc.matches);
						for (loc.m = 1; loc.m lte loc.mEnd; loc.m++)
						{
							// for each match we have for the line, write it to the repo
							loc.matches[loc.m] = REReplace(loc.matches[loc.m], "([^a-zA-Z0-9]l|[^a-zA-Z0-9]localize)[[:space:]]?(\([[:space:]]?['""])", "", "all");
							loc.matches[loc.m] = REReplace(loc.matches[loc.m], "(['""][[:space:]]?)\)", "", "all");							
							
							loc.source = {};
							loc.source.template = loc.file;
							loc.source.line = loc.lineCount;
							$writeTextIntoLocalizationRepository(text=loc.matches[loc.m], source=loc.source);
						}
						// do something here with the data in variable line      
						loc.line = loc.lineReader.readLine();  
						loc.lineCount++;    
					}
				}
			}
		</cfscript>
	</cffunction>
	
	<cffunction name="$findLocalizedText" returntype="string" output="false" access="public">
		<cfargument name="text" type="string" required="true" />
		<cfargument name="struct" type="struct" required="true" />
		<cfargument name="source" type="struct" required="true" />
		<cfscript>
			var loc = {};
			loc.returnValue = "";
			if (StructKeyExists(arguments.struct, arguments.source.template))
				if (StructKeyExists(arguments.struct[arguments.source.template], arguments.source.line))
					if (StructKeyExists(arguments.struct[arguments.source.template][arguments.source.line], arguments.text))
						loc.returnValue = arguments.struct[arguments.source.template][arguments.source.line][arguments.text];
		</cfscript>
		<cfreturn loc.returnValue />
	</cffunction>

	<cffunction name="$getLocalizedText" returnType="struct" output="false" access="public">
		<cfargument name="fromRepository" type="boolean" required="false" default="false" />
		<cfscript>
			var loc = {};
			loc.texts = {}; // initialize this value in case we write a file
			
			if (!arguments.fromRepository)
				loc.currentLocale = getLocaleCode();
			else
				loc.currentLocale = "repository";
			
			loc.includePath = LCase("locales/#loc.currentLocale#.cfm");
			loc.filePath = LCase("plugins/localizer/locales/#loc.currentLocale#.cfm");
			if (FileExists(ExpandPath(loc.filePath)))
				loc.texts = $includeRepository(loc.includePath);
			else
				$file(action="write", file=ExpandPath(loc.filePath), output="");
		</cfscript>
		<cfreturn loc.texts>
	</cffunction>
	
	<cffunction name="$writeTextIntoLocalizationRepository" returnType="void" output="false" access="public" hint="Writes the text to the localization repository">
		<cfargument name="text" type="string" required="true" hint="Text to write" />
		<cfargument name="source" type="struct" required="true" hint="Source of the text to write" />
		<cfset var loc = {} />
		<!--- 
			save texts with a greater nesting to make sure same texts with different casings in different files get saved
			we might have some dups but it will save on the head scratching wondering how something became lower case
			i think this helps make the repository file more self descriptive and the struct if you dump it out
			more nesting is also faster as there are less items per structure
		--->
		<cfsavecontent variable="loc.text"><cfoutput>[cfset loc["#arguments.source.template#"]["#arguments.source.line#"]["#arguments.text#"] = "#arguments.text#"]]</cfoutput></cfsavecontent>
		<cfscript>
			if (!StructKeyExists(request, "localizer") or !StructKeyExists(request.localizer, "writes"))
				request.localizer.writes = {};		
			loc.repo = $getLocalizedText(fromRepository=true);
			// Check first if the variable is written already
			loc.repoString = $findLocalizedText(text=arguments.text, struct=loc.repo, source=arguments.source);
			loc.inRequest = $findLocalizedText(text=arguments.text, struct=request.localizer.writes, source=arguments.source);
			if (!Len(loc.repoString) && !Len(loc.inRequest))
			{
				// transform file output
				loc.text = ReplaceList(loc.text, "[cfset,]]", "<cfset, />");
				$file(action="append", file=ExpandPath("plugins/localizer/locales/repository.cfm"), output=loc.text);
				// when we have template caching turned on in coldfusion, the first version of the template is the one that will be retrieved for the rest of the request, not good
				request.localizer.writes[arguments.source.template][arguments.source.line][arguments.text] = arguments.text;
			}
		</cfscript>
	</cffunction>
	
	<cffunction name="$captureTemplateAndLineNumber" output="false" access="public" returntype="struct">
		<cfscript>
			var loc = {};
			
			loc.ret = $getCallingTemplateInfo();
			// change template name from full to relative path
			loc.ret.template = ListChangeDelims(ReplaceNoCase(loc.ret.template, ExpandPath(application.wheels.webpath), ""), "/", "\/"); // instead of RemoveChars, lets replace the path since replace will cause less issues
		</cfscript>
		<cfreturn loc.ret />
	</cffunction>
	
	<cffunction name="$getCallingTemplateInfo" output="false" access="public" returntype="struct">
		<cfscript>
			var loc = {};
			loc.returnValue = { template = "unknown", line = "unknown"};
			loc.stackTrace = CreateObject("java", "java.lang.Throwable").getStackTrace();
			
			loc.iEnd = ArrayLen(loc.stackTrace);
			for (loc.i = 1; loc.i lte loc.iEnd; loc.i++)
			{
				loc.fileName = loc.stackTrace[loc.i].getFileName();
				if (StructKeyExists(loc, "fileName") && !FindNoCase(".java", loc.fileName) && !FindNoCase("Localizer.cfc", loc.fileName) && !FindNoCase("<generated>", loc.fileName))
				{
					loc.returnValue.template = loc.fileName;
					loc.returnValue.line = loc.stackTrace[loc.i].getLineNumber();
					break;
				}
			}
		</cfscript>
		<cfreturn loc.returnValue />
	</cffunction>
	
	<cffunction name="$includeRepository" output="false" access="public" returntype="struct">
		<cfargument name="template" type="string" required="true" />
		<cfset var loc = {} />
		<cfif !StructKeyExists(request, "localizer") or !StructKeyExists(request.localizer, "cache")>
			<cfset request.localizer.cache = {} />
		</cfif>
		<cfif StructKeyExists(request.localizer.cache, arguments.template)>
			<cfreturn request.localizer.cache[arguments.template] />
		</cfif>
		<cfinclude template="#arguments.template#" />
		<cfset request.localizer.cache[arguments.template] = Duplicate(loc) />
		<cfreturn loc />
	</cffunction>
	
</cfcomponent>
