<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
  <xsl:strip-space elements="*"/>

  <xsl:template match="@*|element()|text()">
    <xsl:copy>
      <xsl:apply-templates select="@*|element()|text()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>