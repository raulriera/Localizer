<h1>Localizer</h1>
<p>Inspired in "Gettext", this plugin adds the ability to localize the texts in a Wheels application. View the source of <tt>/plugins/localizer/Localizer.cfc</tt> for the complete documentation.</p>

<h2>Methods Added</h2>
<p>Here is a listing of the methods that are added by this plugin.</p>

<ul>
	<li>localize</li>
	<li>l</li>
	<li>getLocaleCode</li>
</ul>

<h2>Instructions</h2>
<p>To use this plugin you need to follow these steps:</p>

<ul>
	<li>Pass in the text you wish to localize in the "localize" or "l" function.</li>
	<li>When you execute the code, the plugin will fill a repository.cfm file inside the "locale" folder in /plugins/localizer/</li>
	<li>Copy the text and translate it to the desired language using the locale as the filename, for example: en_US.cfm for English (United States).</li>
	<li>That's it, the plugin will replace your text with its localization the next time you run the code.</li>
</ul>

<a href="<cfoutput>#cgi.http_referer#</cfoutput>"><<< Go Back</a>