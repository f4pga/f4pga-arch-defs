<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:include href="identity.xsl" />

  <!--
    Strip pack_pattern's from input/output tags on pb_types.
    -->
  <xsl:template match="pb_type/input/pack_pattern"/>
  <xsl:template match="pb_type/output/pack_pattern"/>

  <!--
    Convert
       <pack_pattern name="xxx" type="yyy"
    to
       <pack_pattern name="yyy-xxx"
    -->
  <xsl:template match="pack_pattern/@type"/>
  <xsl:template match="pack_pattern[@type]/@name">
    <xsl:attribute name="name">
      <xsl:value-of select="../@type"/>-<xsl:value-of select="../@name"/>
    </xsl:attribute>
  </xsl:template>
  <xsl:template match="pack_pattern[not(@type)]/@name">
    <xsl:copy />
  </xsl:template>
  <xsl:template match="pack_pattern/*">
    <xsl:copy />
  </xsl:template>

  <!--
    Convert
      <interconnect><direct input="IN" output="OUT"><pack_pattern name="PACK"/></direct></interconnect>
    to
      <interconnect><direct input="IN" output="OUT"><pack_pattern name="PACK" in_port="IN" out_port="OUT"/></direct></interconnect>
    -->
  <xsl:template match="direct[@input and @output]/pack_pattern">
    <xsl:copy>
      <xsl:attribute name="in_port"><xsl:value-of select="../@input" /></xsl:attribute>
      <xsl:attribute name="out_port"><xsl:value-of select="../@output" /></xsl:attribute>
      <xsl:apply-templates select="@*"></xsl:apply-templates>
    </xsl:copy>
    <xsl:apply-templates/>
  </xsl:template>

</xsl:stylesheet>
