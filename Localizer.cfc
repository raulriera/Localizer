<cfcomponent output="false">
	
	<cffunction name="init">
		<cfset this.version = "1.0.3,0.9.4">
		<cfreturn this>
	</cffunction>

	<cffunction name="l" returnType="any" output="false" hint="Shortcut method to 'localize'">
		<cfargument name="text" type="string" required="true" hint="Text to localize" />
		
		<cfreturn localize(arguments.text)>
	</cffunction>
	
	<cffunction name="localize" returnType="any" output="false" hint="Harvest the line to localize">
		<cfargument name="text" type="string" required="true" hint="Text to localize" />
		
		<cfset var loc = {}>
		
		<cftry>
			<!--- Check where was this line fired --->
			<cfset loc.source = $captureTemplateAndLineNumber()>
			
			<cfreturn $localize(arguments.text, loc.source)>
			
			<!--- If anything failed, return the original text --->
			<cfcatch type="any">	
				<cfreturn arguments.text>
			</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="$localize" returnType="any" output="false">
		<cfargument name="text" type="string" required="true" hint="Text to localize" />
		<cfargument name="source" type="struct" required="true" hint="Source of the text to write" />
		
		<cfset var loc = {}>
		
		<!--- Escape pound signs --->
		<cfset arguments.text = Replace(arguments.text,"##","####","all")>
		<!--- Find out if the text contains dymanic driven content --->
		<cfset loc.textContainsDynamicText = arguments.text CONTAINS "{" AND arguments.text CONTAINS "}">
		
		<!--- Only fetch from the repository in development mode --->
		<cfif get("environment") IS "design" OR get("environment") IS "development">
			<!--- Get the texts from the repository --->
			<cfset loc.localizedText = $getLocalizedText()>
		<cfelse>
			<!--- Get the texts from the localized repository --->
			<cfset loc.localizedText = $getLocalizedText(false)>
		</cfif>
		
		<cfif loc.textContainsDynamicText>
			<!--- Parse out the content between the "{}" --->
			<cfset loc.textBetweenDynamicText = REMatch("{(.*?)}", arguments.text)>
			
			<!--- Go through the array and replace the parsed values with "{variable}" --->
			<cfloop from="1" to="#ArrayLen(loc.textBetweenDynamicText)#" index="loc.i">
				<cfset arguments.text = Replace(arguments.text, loc.textBetweenDynamicText[loc.i], "{variable}", "all")>
			</cfloop>
		</cfif>
		
		<!--- Return the localized text in the current locale --->
		<cfset loc.searchStruct = StructFindKey(loc.localizedText, arguments.text)>
		
		<!--- Check if the environment is other than production, so that it writes the text into repository --->
		<cfif get("environment") IS "design" OR get("environment") IS "development">
			<cfset $writeTextIntoLocalizationRepository(arguments.text, arguments.source)>
		</cfif>
				
		<cfif IsArray(loc.searchStruct) AND ArrayLen(loc.searchStruct) GT 0>
			<cfset loc.result = loc.searchStruct[1].value>
		<cfelse>
			<cfset loc.result = arguments.text>
		</cfif> 
		
		<!--- Replace back the dynamic content ---> 
		<cfif loc.textContainsDynamicText>
			
			<!--- Go through the array and replace the "{variable}" back with the respective values --->
			<cfloop from="1" to="#ArrayLen(loc.textBetweenDynamicText)#" index="loc.i">
				<cfset loc.result = Replace(loc.result, "{variable}", loc.textBetweenDynamicText[loc.i])>
			</cfloop>
			
			<!--- Remove all "{}" --->
			<cfset loc.result = Replace(loc.result, "{", "", "all")>
			<cfset loc.result = Replace(loc.result, "}", "", "all")>
		</cfif>
		
		<cfreturn loc.result>
	</cffunction>
	
	<cffunction name="getLocaleCode" returnType="string" output="false" hint="Since ColdFusion has several names for locales and not the standard 5 letters code, this function will enforce the return of the locale in the 5 letter code">
		<cfset var loc = {}>
		
		<cfset loc.currentLocale = getLocale()>
		
		<cfif Len(loc.currentLocale) GT 5>
			<cfswitch expression="#loc.currentLocale#">
				<cfcase value="Chinese (China)">
					<cfset loc.currentLocale = "zh_CN">
				</cfcase>
				<cfcase value="Chinese (Hong Kong)">
					<cfset loc.currentLocale = "zh_HK">
				</cfcase>
				<cfcase value="Chinese (Taiwan)">
					<cfset loc.currentLocale = "zh_TW">
				</cfcase>
				<cfcase value="Dutch (Belgian)">
					<cfset loc.currentLocale = "nl_BE">
				</cfcase>
				<cfcase value="Dutch (Standard)">
					<cfset loc.currentLocale = "nl_NL">
				</cfcase>
				<cfcase value="English (Australian)">
					<cfset loc.currentLocale = "en_AU">
				</cfcase>
				<cfcase value="English (Canadian)">
					<cfset loc.currentLocale = "en_CA">
				</cfcase>
				<cfcase value="English (New Zealand)">
					<cfset loc.currentLocale = "en_NZ">
				</cfcase>
				<cfcase value="English (UK)">
					<cfset loc.currentLocale = "en_UK">
				</cfcase>
				<cfcase value="English (US)">
					<cfset loc.currentLocale = "en_US">
				</cfcase>
				<cfcase value="French (Belgian)">
					<cfset loc.currentLocale = "fr_BE">
				</cfcase>
				<cfcase value="French (Canadian)">
					<cfset loc.currentLocale = "fr_CA">
				</cfcase>
				<cfcase value="French (Standard)">
					<cfset loc.currentLocale = "fr_FR">
				</cfcase>
				<cfcase value="French (Swiss)">
					<cfset loc.currentLocale = "fr_CH">
				</cfcase>
				<cfcase value="German (Austrian)">
					<cfset loc.currentLocale = "de_AT">
				</cfcase>
				<cfcase value="German (Standard)">
					<cfset loc.currentLocale = "de_DE">
				</cfcase>
				<cfcase value="German (Swiss)">
					<cfset loc.currentLocale = "de_CH">
				</cfcase>
				<cfcase value="Italian (Standard)">
					<cfset loc.currentLocale = "it_IT">
				</cfcase>
				<cfcase value="Italian (Swiss)">
					<cfset loc.currentLocale = "it_CH">
				</cfcase>
				<cfcase value="Japanese">
					<cfset loc.currentLocale = "ja_JP">
				</cfcase>
				<cfcase value="Korean">
					<cfset loc.currentLocale = "ko_KR">
				</cfcase>
				<cfcase value="Norwegian (Bokmal)">
					<cfset loc.currentLocale = "nb_NO">
				</cfcase>
				<cfcase value="Norwegian (Nynorsk)">
					<cfset loc.currentLocale = "nn_NO">
				</cfcase>
				<cfcase value="Portuguese (Brazilian)">
					<cfset loc.currentLocale = "pt_BR">
				</cfcase>
				<cfcase value="Portuguese (Standard)">
					<cfset loc.currentLocale = "pt_PT">
				</cfcase>
				<cfcase value="Spanish (Modern)">
					<cfset loc.currentLocale = "es_ES">
				</cfcase>
				<cfcase value="Spanish (Standard)">
					<cfset loc.currentLocale = "es_ES">
				</cfcase>
				<cfcase value="Swedish">
					<cfset loc.currentLocale = "sv_SE">
				</cfcase>
				
			</cfswitch>
		</cfif>
		
		<cfreturn loc.currentLocale>
	</cffunction>

	<cffunction name="$getLocalizedText" returnType="struct" output="false">
		<cfargument name="fromRepository" type="boolean" required="false" default="true" />
		
		<cfset var loc = {}>
		<cfset $localizer = {}>
		
		<cfif arguments.fromRepository IS false>
			<cfset loc.currentLocale = getLocaleCode()>
		<cfelse>
			<cfset loc.currentLocale = "repository">
		</cfif>
		
		<!--- Build the file path --->
		<cfset loc.filePath = "plugins/localizer/locales/#loc.currentLocale#.cfm">
					
		<!--- Check if the file exists --->
		<cfif FileExists(ExpandPath(loc.filePath))>
			<cfinclude template="locales/#loc.currentLocale#.cfm" />
		<!--- Otherwise, create it --->
		<cfelse>
			<cffile action="write" file="#ExpandPath(loc.filePath)#" output="" mode="777" />
		</cfif>
	
		<cfreturn $localizer>
	</cffunction>
	
	<cffunction name="$writeTextIntoLocalizationRepository" returnType="void" output="false" hint="Writes the text to the localization repository">
		<cfargument name="text" type="string" required="true" hint="Text to write" />
		<cfargument name="source" type="struct" required="true" hint="Source of the text to write" />
		
		<cfset var loc = {}>
		
		<!--- Check first if the variable is written already --->
		<cfset loc.searchStruct = StructFindKey($getLocalizedText(true), arguments.text)>
		
		<!--- If nothing was found --->
		<cfif ArrayLen(loc.searchStruct) LTE 0>	
			<cfoutput>
			<cfsavecontent variable="loc.text">[cfset $localizer['''#arguments.text#'''] = '''#arguments.text#''']] <!-- #arguments.source.template# ###arguments.source.line# --></cfsavecontent>
			</cfoutput>
			
			<!--- Replace placeholders --->
			<cfset loc.text = Replace(loc.text, "[cfset", "<cfset")>
			<cfset loc.text = Replace(loc.text, "''']]", "'''>")>
			<cfset loc.text = Replace(loc.text, "'''", '"', "all")>
			<cfset loc.text = Replace(loc.text, "<!--", '<!---', "all")>
			<cfset loc.text = Replace(loc.text, "-->", '--->', "all")>
			
			<cffile action="append" file="#ExpandPath('plugins/localizer/locales/repository.cfm')#" output="#loc.text#" />
		</cfif>
		
	</cffunction>
	
	<cffunction name="$captureTemplateAndLineNumber" output="false">
		<cfset var loc = {}>
		
		<!--- Set return value --->
		<cfset loc.ret = {line="", template=""}>
		
		<!--- Create an exception so we can get the TagContext and display what file and line number --->
		<cfset loc.exception = createObject("java","java.lang.Exception").init()>
		<cfset loc.tagcontext = loc.exception.tagcontext>
		<!--- 
		TagContext is an array. The first element of the array will always be the context for this
		method announcing the deprecation. The second element will be the deprecated function that
		is being called. We need to look at the third element of the array to get the method that
		is calling the method marked for deprecation.
		 --->
		<cfif isArray(loc.tagcontext) and arraylen(loc.tagcontext) gte 3 and isStruct(loc.tagcontext[3])>
			<!--- grab and parse the information from the tagcontext. --->
			<cfset loc.context = loc.tagcontext[3]>
			<!--- the line number --->
			<cfset loc.ret.line = loc.context.line>
			<!--- the user template where the method called occurred --->
			<cfset loc.ret.template = loc.context.template>		
			<!--- change template name from full to relative path. --->
			<cfset loc.ret.template = listchangedelims(removechars(loc.ret.template, 1, len(expandpath(application.wheels.webpath))), "/", "\/")>
		</cfif>
		
		<cfreturn loc.ret>
	</cffunction>
	
	<!--- Overwrites to Wheels core functions --->
	<cffunction name="distanceOfTimeInWords" returntype="string" access="public" output="false"
		hint="Pass in two dates to this method, and it will return a string describing the difference between them.">
		<cfargument name="fromTime" type="date" required="true" hint="Date to compare from">
		<cfargument name="toTime" type="date" required="true" hint="Date to compare to">
		<cfargument name="includeSeconds" type="boolean" required="false" default="#application.wheels.functions.distanceOfTimeInWords.includeSeconds#" hint="Whether or not to include the number of seconds in the returned string">
		<cfscript>
			var loc = {};
			loc.minuteDiff = DateDiff("n", arguments.fromTime, arguments.toTime);
			loc.secondDiff = DateDiff("s", arguments.fromTime, arguments.toTime);
			loc.hours = 0;
			loc.days = 0;
			loc.returnValue = "";
	
			if (loc.minuteDiff <= 1)
			{
				if (arguments.includeSeconds && loc.secondDiff < 60)
				{
					if (loc.secondDiff < 5)
						loc.returnValue = l("less than 5 seconds");
					else if (loc.secondDiff < 10)
						loc.returnValue = l("less than 10 seconds");
					else if (loc.secondDiff < 20)
						loc.returnValue = l("less than 20 seconds");
					else if (loc.secondDiff < 40)
						loc.returnValue = l("half a minute");
					else
						loc.returnValue = l("less than a minute");
				}
				else
				{
					loc.returnValue = l("1 minute");
				}
			}
			else if (loc.minuteDiff < 45)
			{
				loc.returnValue = loc.minuteDiff & " " & l("minutes");
			}
			else if (loc.minuteDiff < 90)
			{
				loc.returnValue = l("about 1 hour");
			}
			else if (loc.minuteDiff < 1440)
			{
				loc.hours = Ceiling(loc.minuteDiff/60);
				loc.returnValue = l("about") & " " & loc.hours & " " & l("hours");
			}
			else if (loc.minuteDiff < 2880)
			{
				loc.returnValue = l("1 day");
			}
			else if (loc.minuteDiff < 43200)
			{
				loc.days = Int(loc.minuteDiff/1440);
				loc.returnValue = loc.days & " " & l("days");
			}
			else if (loc.minuteDiff < 86400)
			{
				loc.returnValue = l("about 1 month");
			}
			else if (loc.minuteDiff < 525600)
			{
				loc.months = Int(loc.minuteDiff/43200);
				loc.returnValue = loc.months & " " & l("months");
			}
			else if (loc.minuteDiff < 1051200)
			{
				loc.returnValue = l("about 1 year");
			}
			else if (loc.minuteDiff > 1051200)
			{
				loc.years = Int(loc.minuteDiff/525600);
				loc.returnValue = l("over") & " " & loc.years & " " & l("years");
			}
		</cfscript>
		<cfreturn loc.returnValue>
	</cffunction>	
</cfcomponent>
