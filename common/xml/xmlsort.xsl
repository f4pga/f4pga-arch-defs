<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:output method="xml" indent="yes"/>
  <xsl:strip-space elements="*"/>

  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="*">
    <xsl:copy>
      <!-- Sort the attributes by name and remove the xml:base attribute -->
      <xsl:for-each select="@*[name()!='xml:base']">
	<xsl:sort select="name( . )" order="ascending"/>
	<xsl:attribute name="{local-name()}"><xsl:value-of select="normalize-space(.)"/></xsl:attribute>
      </xsl:for-each>
      <xsl:apply-templates>
        <xsl:sort select="." />
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <!-- Allow from attribute which gives you a relative to a given pb_type -->
  <xsl:template name="from-pb_type">
    <xsl:choose>
      <xsl:when test="@from='current'"><xsl:value-of select="ancestor::pb_type[1]/@name"/></xsl:when>
      <xsl:when test="@from"><xsl:value-of select="@from"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="ancestor::pb_type[1]/@name"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
    Convert
     * <port name=XXX> 				to XXX
     * <port name=XXX bit=Y> 			to XXX[Y]
     * <port name=XXX bit_msb=M bit_lsb=L>	to XXX[M:L]
    -->
  <xsl:template name="port-value"><xsl:value-of select="@name"/><xsl:choose><xsl:when test="@bit">[<xsl:value-of select="@bit"/>]</xsl:when><xsl:when test="@bit-msb">[<xsl:value-of select="@bit-msb"/>:<xsl:value-of select="@bit-lsb"/>]</xsl:when><xsl:otherwise></xsl:otherwise></xsl:choose></xsl:template>

  <!--
    Convert
      <interconnect><XXX><port type='input' ...><port type='output' ...></XXX><YYY../></interconnect>
    to
      <interconnect><XXX input='...' output='...'><YYY../></XXX></interconnect>
    -->
  <xsl:template match="interconnect/*/port[@type='input']">
    <xsl:attribute name="input"><xsl:call-template name="from-pb_type"/>.<xsl:call-template name="port-value"/></xsl:attribute>
  </xsl:template>
  <xsl:template match="interconnect/*/port[@type='output']">
    <xsl:attribute name="name"><xsl:call-template name="from-pb_type"/>-<xsl:call-template name="port-value"/></xsl:attribute>
    <xsl:attribute name="output"><xsl:call-template name="from-pb_type"/>.<xsl:call-template name="port-value"/></xsl:attribute>
  </xsl:template>
  <!--
    Convert
      <loc ...><port ...><port ...></loc>
    to
      <loc ...>BLOCK.PORT BLOCK.PORT</loc>
    -->
  <xsl:template match="loc/port"><xsl:text>
      </xsl:text><xsl:call-template name="from-pb_type"/>.<xsl:call-template name="port-value"/>
  </xsl:template>
  <xsl:template match="loc/port[last()]"><xsl:text>
      </xsl:text><xsl:call-template name="from-pb_type"/>.<xsl:call-template name="port-value"/><xsl:text>
    </xsl:text>
  </xsl:template>

  <!-- Remove duplicate model nodes -->
  <xsl:key name="model-by-name" match="model" use="@name" />
  <xsl:template match="models">
    <models>
      <xsl:for-each select="model[count(. | key('model-by-name', @name)[1]) = 1]">
        <xsl:copy>
          <xsl:attribute name="name"><xsl:value-of select="@name"/></xsl:attribute>
          <xsl:apply-templates/>
        </xsl:copy>
      </xsl:for-each>
    </models>
  </xsl:template>

  <xsl:template match="text()|comment()|processing-instruction()">
    <xsl:copy/>
  </xsl:template>

</xsl:stylesheet>
