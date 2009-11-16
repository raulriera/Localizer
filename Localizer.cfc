<cfcomponent output="false">
	
	<cffunction name="init">
		<cfset this.version = "0.9.4">
		<cfreturn this>
	</cffunction>

	<cffunction name="l" returnType="any" output="false" hint="Shortcut method to 'localize'">
		<cfargument name="text" type="string" required="true" hint="Text to localize" />
		
		<cfset var loc = {}>
		
		<cftry>
			<!--- Check where was this line fired --->
			<cfset loc.source = $captureTemplateAndLineNumber()>
			
			<cfreturn localize(arguments.text, loc.source)>
		
			<cfcatch type="any">	
				<cfreturn arguments.text>
			</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="localize" returnType="any" output="false">
		<cfargument name="text" type="string" required="true" hint="Text to localize" />
		<cfargument name="source" type="struct" required="true" hint="Source of the text to write" />
		
		<cfset var loc = {}>
		<cfset loc.textContainsDynamicText = arguments.text CONTAINS "{" AND arguments.text CONTAINS "}">
		
		<cfif get("environment") IS "design">
			<cfset loc.localizedText = $getLocalizedText()>
		<cfelse>
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
		<cfif get("environment") IS "design">
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
				<cfcase value="English (US)">
					<cfset loc.currentLocale = "en_US">
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
		
		<cfif arguments.fromRepository IS false>
			<cfset loc.currentLocale = getLocaleCode()>
		<cfelse>
			<cfset loc.currentLocale = "repository">
		</cfif>
		
		<cfset loc.filePath = "plugins/localizer/locales/#loc.currentLocale#.cfm">
		
		<!--- Check if the file exists --->
		<cfif FileExists(ExpandPath(loc.filePath))>
			<cfinclude template="locales/#loc.currentLocale#.cfm" />
		<!--- Otherwise, create it --->
		<cfelse>
			<cffile action="write" file="#ExpandPath(loc.filePath)#" output="" />
		</cfif>
	
		<cfreturn loc>
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
			<cfsavecontent variable="loc.text">[cfset loc['''#arguments.text#'''] = '''#arguments.text#''']] <!-- #arguments.source.template# ###arguments.source.line# --></cfsavecontent>
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
=			<!--- change template name from full to relative path. --->
			<cfset loc.ret.template = listchangedelims(removechars(loc.ret.template, 1, len(expandpath(application.wheels.webpath))), "/", "\/")>
		</cfif>
		
		<cfreturn loc.ret>
	</cffunction>
	
</cfcomponent>
