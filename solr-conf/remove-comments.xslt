<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
  <xsl:strip-space elements="*"/>

  <xsl:template match="@*|element()|text()">
    <xsl:copy>
      <xsl:apply-templates select="@*|element()|text()"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="str[@name='hl.bs.chars']">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:value-of disable-output-escaping="true" select="'.,!? &amp;#9;&amp;#10;&amp;#13;'"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>