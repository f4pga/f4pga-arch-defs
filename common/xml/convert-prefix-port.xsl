<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:include href="identity.xsl" />

  <!-- template-function: Allow from attribute which gives you a relative to a given pb_type -->
  <xsl:template name="parent-pb_type">
    <xsl:value-of select="ancestor::pb_type[1]/@name"/>
  </xsl:template>

  <xsl:template match="pack_pattern/@in_port">
    <xsl:copy />
  </xsl:template>
  <xsl:template match="pack_pattern/@out_port">
    <xsl:copy />
  </xsl:template>

  <!-- Prefix in_port / out_port values with the parent name. -->
  <xsl:template match="@out_port">
    <xsl:attribute name="out_port"><xsl:call-template name="parent-pb_type"/>.<xsl:value-of select="."/></xsl:attribute>
  </xsl:template>
  <xsl:template match="@in_port">
    <xsl:attribute name="in_port"><xsl:call-template name="parent-pb_type"/>.<xsl:value-of select="."/></xsl:attribute>
  </xsl:template>
  <xsl:template match="@port">
    <xsl:attribute name="port"><xsl:call-template name="parent-pb_type"/>.<xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

</xsl:stylesheet>
