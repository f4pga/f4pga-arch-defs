<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:include href="identity.xsl" />

  <!--
    Convert
      <pb_type><blif_model>XXX</blif_model></pb_type>
    to
      <pb_type blif_model="XXX"></pb_type>
    -->
  <xsl:template match="pb_type/blif_model">
    <xsl:attribute name="blif_model"><xsl:value-of select="text()"/></xsl:attribute>
  </xsl:template>

  <!--
    Convert
      <pb_type><pb_class>XXX</pb_class></pb_type>
    to
      <pb_type class="XXX"></pb_type>
    -->
  <xsl:template match="pb_type/pb_class">
    <xsl:attribute name="class"><xsl:value-of select="text()"/></xsl:attribute>
  </xsl:template>

</xsl:stylesheet>
