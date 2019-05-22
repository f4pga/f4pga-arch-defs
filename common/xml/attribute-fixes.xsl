<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:include href="identity.xsl" />

  <!-- Strip xml:base attribute -->
  <xsl:template match="@xml:base"/>

  <!-- Normalize space around attributes on a tag -->
  <xsl:template match="@*">
    <xsl:copy>
      <xsl:value-of select="normalize-space( . )" />
    </xsl:copy>
  </xsl:template>

  <!-- Sort the attributes by name -->
  <xsl:template match="*">
    <xsl:copy>
      <xsl:for-each select="@*[name()!='xml:base']">
        <xsl:sort select="name( . )"/>
        <xsl:attribute name="{local-name()}"><xsl:value-of select="normalize-space(.)"/></xsl:attribute>
      </xsl:for-each>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
