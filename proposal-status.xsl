<!--
This file renders the contents of proposals.xml as a nicely-formatted HTML page.
The proposal data and this template are loaded using JavaScript (see index.html
on the gh-pages branch).
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html"/>

  <!-- The main template, which renders the page body. -->
  <xsl:template match="/proposals">
    <html>
      <head>
        <title>SDL Evolution Proposal Status</title>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <xsl:call-template name="css"/>
      </head>
      <body>
        <h1>SDL Evolution Proposal Status</h1>
      
        <p>The <a href="https://github.com/smartdevicelink/sdl_evolution/blob/master/process.md">SDL evolution process</a> describes the process by which SDL evolves. This page tracks the currently active proposals in that process.</p>
      
        <xsl:call-template name="section">
          <xsl:with-param name="title">Active reviews</xsl:with-param>
          <xsl:with-param name="proposals" select="proposal[@status='active']"/>
        </xsl:call-template>
      
        <!-- <xsl:call-template name="section">
          <xsl:with-param name="title">Upcoming reviews</xsl:with-param>
          <xsl:with-param name="proposals" select="proposal[@status='scheduled']"/>
        </xsl:call-template> -->
        
        <xsl:call-template name="section">
          <xsl:with-param name="title">Accepted (awaiting implementation)</xsl:with-param>
          <xsl:with-param name="description">This is the list of proposals which have been accepted for inclusion into SDL, but they are not implemented yet, and may not have anyone signed up to implement them. If they are not implemented in time for the next version of SDL, they will roll into a subsequent release.</xsl:with-param>
          <xsl:with-param name="proposals" select="proposal[@status='accepted']"/>
        </xsl:call-template>
      
        <!-- This needs to include both version and platform -->
        <xsl:call-template name="section">
          <xsl:with-param name="title">Implemented for SDL iOS v5.0</xsl:with-param>
          <xsl:with-param name="proposals" select="proposal[@status='implemented'][@primary-platform='ios'][@sdl-version='5.0']"/>
        </xsl:call-template>
      
        <xsl:call-template name="section">
          <xsl:with-param name="title">Implemented for SDL Android v4.3</xsl:with-param>
          <xsl:with-param name="proposals" select="proposal[@status='implemented'][@primary-platform='android'][@sdl-version='4.3']"/>
        </xsl:call-template>
        
        <xsl:call-template name="section">
          <xsl:with-param name="title">Implemented for SDL Core v4.2.3</xsl:with-param>
          <xsl:with-param name="proposals" select="proposal[@status='implemented'][@primary-platform='core'][@sdl-version='4.2.3']"/>
        </xsl:call-template>
        
        <xsl:call-template name="section">
          <xsl:with-param name="title">Implemented for SDL Core v4.3</xsl:with-param>
          <xsl:with-param name="proposals" select="proposal[@status='implemented'][@primary-platform='core'][@sdl-version='4.3']"/>
        </xsl:call-template>
        
        <xsl:call-template name="section">
          <xsl:with-param name="title">Deferred for future discussion</xsl:with-param>
          <xsl:with-param name="proposals" select="proposal[@status='deferred']"/>
        </xsl:call-template>
      
        <xsl:call-template name="section">
          <xsl:with-param name="title">Returned for revision</xsl:with-param>
          <xsl:with-param name="proposals" select="proposal[@status='returned']"/>
        </xsl:call-template>
      
        <xsl:call-template name="section">
          <xsl:with-param name="title">Rejected or withdrawn</xsl:with-param>
          <xsl:with-param name="proposals" select="proposal[@status='rejected']"/>
        </xsl:call-template>
      </body>
    </html>
  </xsl:template>

  <!-- Renders a section header and a table of proposals. -->
  <xsl:template name="section">
    <xsl:param name="title"/>
    <xsl:param name="description"/>
    <xsl:param name="proposals"/>
    <section>
      <h2><xsl:value-of select="$title"/></h2>
      <xsl:if test="$description"><p><xsl:value-of select="$description"/></p></xsl:if>
      <xsl:choose>
        <xsl:when test="count($proposals) = 0">
          <p>(none)</p>
        </xsl:when>
        <xsl:otherwise>
          <table>
            <xsl:apply-templates select="$proposals">
              <xsl:sort select="@id" order="ascending"/>
            </xsl:apply-templates>
          </table>
        </xsl:otherwise>
      </xsl:choose>
    </section>
  </xsl:template>

  <!-- Renders a single proposal. -->
  <xsl:template match="proposal">
    <tr class="proposal">
      <td><a class="number status-{@status}" href="https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/{@filename}">SDL-<xsl:value-of select="@id"/></a></td>
      <td><a class="number platform-{@primary-platform}" href="https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/{@filename}"><xsl:value-of select="@primary-platform"/></a></td>
      <td>
        <a class="title" href="https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/{@filename}">
          <xsl:call-template name="format-proposal-name">
            <xsl:with-param name="name" select="@name"/>
          </xsl:call-template>
        </a>
      </td>
    </tr>
  </xsl:template>
  
  <!-- Converts inline `code` in a proposal name to <code></code> elements. -->
  <xsl:template name="format-proposal-name">
    <xsl:param name="name"/>
    <xsl:choose>
      <xsl:when test="contains($name, '`')">
        <xsl:variable name="before-open-tick" select="substring-before($name, '`')"/>
        <xsl:variable name="after-open-tick" select="substring-after($name, '`')"/>
        <xsl:variable name="between-ticks" select="substring-before($after-open-tick, '`')"/>
        <xsl:variable name="after-close-tick" select="substring-after($after-open-tick, '`')"/>
        
        <!-- Render up to and including the first occurrence of `code` -->
        <xsl:value-of select="$before-open-tick"/>
        <code><xsl:value-of select="$between-ticks"/></code>
        
        <!-- Recursively format the rest of the string  -->
        <xsl:call-template name="format-proposal-name">
          <xsl:with-param name="name" select="$after-close-tick"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$name"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="css">
    <style type="text/css">
      * {
        margin: 0;
        padding: 0;
      }
      body {
        font-family: -apple-system, BlinkMacSystemFont, HelveticaNeue, Helvetica, Arial, sans-serif;
        -webkit-text-size-adjust: none;
      }
      body > h1, body > p, section > table, section > p {
        margin-left: 1rem;
        margin-right: 1rem;
      }
      p {
        margin-top: 1em;
        margin-bottom: 1em;
        line-height: 1.5em;
      }
      code {
        font-family: "SFMono-Regular", Menlo, Consolas, monospace;
        font-size: 90%;
        padding: 0.2em 0.3em;
        background-color: #f7f7f7;
        border-radius: 3px;
      }
      h1 {
        margin-top: 0.6em;
        margin-bottom: 0.6em;
      }
      h2 {
        margin: 0.5em 0em 0em;
        padding: 0.3em 1rem 0.4em;
        position: -webkit-sticky;
        position: -moz-sticky;
        position: -ms-sticky;
        position: -o-sticky;
        position: sticky;
        top: 0px;
        background-color: #fff;
      }
      @supports (backdrop-filter: blur(10px)) or (-webkit-backdrop-filter: blur(10px)) {
        h2 {
          background-color: rgba(255, 255, 255, 0.5);
          backdrop-filter: blur(10px);
          -webkit-backdrop-filter: blur(10px);
        }
      }
      h2 + p {
        margin-top: 0;
      }
      a {
        color: #4078c0;
        text-decoration: none;
      }
      a:hover, a:visited:hover {
        text-decoration: underline;
      }
      .proposal a.title {
        color: #647686; // SDL Steel
      }
      .proposal a.title:visited {
        color: #8f9eac; // SDL Platinum
      }
      .proposal a.title:hover, .proposal a.title:visited:hover {
        color: #202c36; // SDL Black
      }
      table {
        margin-bottom: 1rem;
        border-spacing: 0.5em;
      }
      table, tr, td {
        padding: 0;
      }
      .proposal {
        font-size: 1.1em;
      }
      .proposal td {
        vertical-align: top;
      }
      .number {
        text-align: center;
        border-radius: 5px;
        font-size: 0.7em;
        font-weight: bold;
        padding: 0.2em 0.5em;
        display: block;
        white-space: nowrap;
        color: #f9fbfe; // SDL Ice
      }
      .proposal a.number {
        color: #f9fbfe;
        text-decoration: none;
      }
      a.number.status-implemented {
        background-color: #4ea57f; // SDL Forest
      }
      a.number.status-accepted {
        background-color: #7ebc79; // SDL Lime
      }
      a.number.status-active {
        background-color: #39609a; // SDL Navy
      }
      a.number.status-scheduled {
        background-color: #58bcb9; // SDL Teal
      }
      a.number.status-awaiting, a.number.status-deferred {
        background-color: #bac6d2; // SDL Grey
        color: #000;
      }
      a.number.status-returned {
        background-color: #c691c5; // SDL Purple
      }
      a.number.status-rejected {
        background-color: #ef5e69; // SDL Red
      }
      a.number.platform-protocol {
        background-color: #fb9050; // SDL Orange
      }
      a.number.platform-rpc {
        background-color: #c691c5; // SDL Purple
      }
      a.number.platform-core {
        background-color: #ef5e69; // SDL Red
      }
      a.number.platform-ios {
        background-color: #39609a; // SDL Navy
      }
      a.number.platform-android {
        background-color: #4ea57f; // SDL Forest
      }
      a.number.platform-meta {
        background-color: #58bcb9; // SDL Teal
      }
        a.number.platform-policy {
        background-color: #394e50; // SDL Dark Grey
      }
    </style>
  </xsl:template>

</xsl:stylesheet>
