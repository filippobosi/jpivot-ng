<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	
	<xsl:param name="imgpath" select="'stpivot/style/wcf/changeorder'"/>
	
	<xsl:template match="move-button[@style='fwd']">
		<input border="0" type="image" name="{@id}" src="{$context}/{$imgpath}/move-down.png" width="9" height="9" class="imgButton"/>
	</xsl:template>
	
	<xsl:template match="move-button[@style='bwd']">
		<input border="0" type="image" name="{@id}" src="{$context}/{$imgpath}/move-up.png" width="9" height="9" class="imgButton"/>
	</xsl:template>
	
	<xsl:template match="move-button[@style='cut']">
		<input border="0" type="image" name="{@id}" src="{$context}/{$imgpath}/cut.png" width="9" height="9" title="{@title}" class="imgButton"/>
	</xsl:template>
	
	<xsl:template match="move-button[@style='uncut']">
		<input border="0" type="image" name="{@id}" src="{$context}/{$imgpath}/uncut.png" width="9" height="9" title="{@title}" class="imgButton"/>
	</xsl:template>
	
	<xsl:template match="move-button[@style='paste-before']">
		<input border="0" type="image" name="{@id}" src="{$context}/{$imgpath}/paste-before.png" width="9" height="9" title="{@title}" class="imgButton"/>
	</xsl:template>
	
	<xsl:template match="move-button[@style='paste-after']">
		<input border="0" type="image" name="{@id}" src="{$context}/{$imgpath}/paste-after.png" width="9" height="9" title="{@title}" class="imgButton"/>
	</xsl:template>
	
	<xsl:template match="move-button">
		<img src="{$context}/{$imgpath}/move-empty.png" width="9" height="9" class="imgButton"/>
	</xsl:template>

</xsl:stylesheet>