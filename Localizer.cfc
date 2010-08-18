<cfcomponent output="false">
	
	<cffunction name="init" access="public" output="false" returntype="any">
		<cfset this.version = "0.9.3,1.0,1.1">
		<cfreturn this />
	</cffunction>
	
	<cffunction name="l" returntype="any" output="false" access="public" hint="Shortcut method to 'localize'">
		<cfargument name="text" type="string" required="true" hint="Text to localize" />
		<cfscript>
			try
			{
				return localize(arguments.text, $captureTemplateAndLineNumber());
			}
			catch (Any e) 
			{
				// do nothing with errors
			}
		</cfscript>
		<cfreturn arguments.text />
	</cffunction>


	<cffunction name="localize" returnType="any" output="false" access="public">
		<cfargument name="text" type="string" required="true" hint="Text to localize" />
		<cfargument name="source" type="struct" required="true" hint="Source of the text to write" />
		<cfscript>
			var loc = {};
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
			else if (Len(loc.searchStruct))
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
				case "Norwegian (Bokmal)":     { loc.currentLocale = "nb_NO"; break; }
				case "Norwegian (Nynorsk)":    { loc.currentLocale = "no_NO"; break; }
				case "Portuguese (Brazilian)": { loc.currentLocale = "pt_BR"; break; }
				case "Portuguese (Standard)":  { loc.currentLocale = "pt_PT"; break; }
				case "Spanish (Mexican)":      { loc.currentLocale = "es_MX"; break; }
				case "Spanish (Modern)":       { loc.currentLocale = "es_US"; break; }
				case "Spanish (Standard)":     { loc.currentLocale = "es_ES"; break; }
				case "Swedish":                { loc.currentLocale = "sv_SE"; break; }
			}
		</cfscript>
		<cfreturn loc.currentLocale>
	</cffunction>
	
	<cffunction name="$findLocalizedText" returntype="string" output="false" access="public">
		<cfargument name="text" type="string" required="true" />
		<cfargument name="struct" type="struct" required="true" />
		<cfargument name="source" type="struct" required="true" />
		<cfscript>
			var returnValue = "";
			if (StructKeyExists(arguments.struct, arguments.source.template))
				if (StructKeyExists(arguments.struct[arguments.source.template], arguments.source.line))
					if (StructKeyExists(arguments.struct[arguments.source.template][arguments.source.line], arguments.text))
						returnValue = arguments.struct[arguments.source.template][arguments.source.line][arguments.text];
		</cfscript>
		<cfreturn returnValue />
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
		<cfsavecontent variable="loc.text"><cfoutput>[cfset loc.texts["#arguments.source.template#"]["#arguments.source.line#"]["#arguments.text#"] = "#arguments.text#"]]</cfoutput></cfsavecontent>
		<cfscript>
			// Check first if the variable is written already
			loc.searchStruct = $findLocalizedText(text=arguments.text, struct=$getLocalizedText(fromRepository=true), source=arguments.source);
			if (!ArrayLen(loc.searchStruct))
			{
				// transform file output
				loc.text = ReplaceList(loc.text, "[cfset,]]", "<cfset, />");
				$file(action="append", file=ExpandPath("plugins/localizer/locales/repository.cfm"), output=loc.text);
			}
		</cfscript>
	</cffunction>
	
	<cffunction name="$captureTemplateAndLineNumber" output="false" access="public" returntype="struct">
		<cfscript>
			var loc = {};
			// Set return value
			loc.ret = { line="", template="" };
			// Create an exception so we can get the TagContext and display what file and line number
			loc.exception = CreateObject("java","java.lang.Exception").init();
			loc.tagcontext = loc.exception.tagcontext;
			// TagContext is an array. The first element of the array will always be the context for this
			// method announcing the deprecation. The second element will be the deprecated function that
			// is being called. We need to look at the third element of the array to get the method that
			// is calling the method marked for deprecation.
			if (IsArray(loc.tagcontext) and Arraylen(loc.tagcontext) gte 3 and IsStruct(loc.tagcontext[3]))	
			{
				// grab and parse the information from the tagcontext.
				loc.context = loc.tagcontext[3];
				// the line number
				loc.ret.line = loc.context.line;
				// the user template where the method called occurred
				loc.ret.template = loc.context.template;
				// change template name from full to relative path
				loc.ret.template = ListChangeDelims(RemoveChars(loc.ret.template, 1, Len(ExpandPath(application.wheels.webpath))), "/", "\/");
			}	
		</cfscript>
		<cfreturn loc.ret />
	</cffunction>
	
	<cffunction name="$includeRepository" output="false" access="public" returntype="struct">
		<cfargument name="template" type="string" required="true" />
		<cfset var loc = {} />
		<cfset loc.texts = {} />
		<cfinclude template="#arguments.template#" />
		<cfreturn loc.texts />
	</cffunction>
	
</cfcomponent>
