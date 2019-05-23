<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes"/>
  <xsl:strip-space elements="*"/>

  <xsl:template match="@*">
    <xsl:copy/>
  </xsl:template>

  <xsl:template match="*">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="text()|processing-instruction()">
    <xsl:copy>
      <xsl:apply-templates select="text()|processing-instruction()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:param name="strip_comments" select="''" />
  <xsl:template match="comment()">
    <xsl:choose>
      <xsl:when test="$strip_comments"></xsl:when>
      <xsl:otherwise><xsl:copy /></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
