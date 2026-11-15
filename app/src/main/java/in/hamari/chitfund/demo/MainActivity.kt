package `in`.hamari.chitfund.demo

import android.app.Activity
import android.os.Bundle
import android.graphics.*
import android.view.View
import android.view.Window
import android.view.WindowManager
import kotlin.math.min

class MainActivity : Activity() {
    @Suppress("DEPRECATION")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN)
        window.decorView.systemUiVisibility = (View.SYSTEM_UI_FLAG_FULLSCREEN or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or View.SYSTEM_UI_FLAG_LAYOUT_STABLE)
        setContentView(HomeDesignView(this))
    }
}

private class HomeDesignView(context: android.content.Context) : View(context) {
    private val p = Paint(Paint.ANTI_ALIAS_FLAG or Paint.SUBPIXEL_TEXT_FLAG)
    private val bg = Color.rgb(235, 241, 234)
    private val ink = Color.rgb(24, 43, 36)
    private val green = Color.rgb(28, 67, 54)
    private val pale = Color.rgb(222, 235, 222)
    private val white = Color.rgb(250, 251, 247)
    private val scaleUnit get() = min(width / 864f, height / 1536f)

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val s = scaleUnit
        val left = (width - 864f * s) / 2f
        val top = (height - 1536f * s) / 2f
        canvas.drawColor(bg)
        canvas.save(); canvas.translate(left, top); canvas.scale(s, s)
        drawBackground(canvas)
        drawHeader(canvas)
        drawHero(canvas)
        drawStats(canvas)
        drawActions(canvas)
        drawActivity(canvas)
        drawBottomNav(canvas)
        canvas.restore()
    }

    private fun paint(color: Int, style: Paint.Style = Paint.Style.FILL): Paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color=color; this.style=style }
    private fun rounded(c: Canvas, l: Float,t: Float,r: Float,b: Float,rad: Float, color: Int, shadow: Boolean=false) {
        val q=paint(color)
        if(shadow) q.setShadowLayer(18f,0f,10f,0x300d2b20.toInt())
        c.drawRoundRect(l,t,r,b,rad,rad,q); q.clearShadowLayer()
    }
    private fun gradientCard(c:Canvas,l:Float,t:Float,r:Float,b:Float,rad:Float,topColor:Int,bottomColor:Int) {
        val q=paint(Color.WHITE); q.shader=LinearGradient(l,t,l,b,topColor,bottomColor,Shader.TileMode.CLAMP); q.setShadowLayer(17f,0f,9f,0x290b241b.toInt()); c.drawRoundRect(l,t,r,b,rad,rad,q); q.shader=null; q.clearShadowLayer()
        c.drawRoundRect(l+2,t+2,r-2,b-2,rad,rad,paint(0x18ffffff.toInt()))
    }
    private fun text(c:Canvas,str:String,x:Float,y:Float,size:Float,color:Int=ink,bold:Boolean=false,align:Paint.Align=Paint.Align.LEFT) {
        val q=paint(color); q.textSize=size; q.typeface=if(bold) Typeface.create("sans-serif",Typeface.BOLD) else Typeface.create("sans-serif",Typeface.NORMAL); q.textAlign=align; c.drawText(str,x,y,q)
    }
    private fun drawBackground(c:Canvas){
        val q=paint(0x0c78927f.toInt()); for(y in 20..1530 step 34) for(x in 12..850 step 37) c.drawCircle(x.toFloat(),y.toFloat(),0.7f,q)
        val wash=paint(0x16ffffff.toInt()); c.drawCircle(430f,190f,270f,wash)
    }
    private fun drawHeader(c:Canvas){
        // emblem medallion
        val sh=paint(white); sh.setShadowLayer(15f,0f,7f,0x260d2b20.toInt()); c.drawCircle(110f,153f,66f,sh); sh.clearShadowLayer(); c.drawCircle(110f,153f,59f,paint(0xfff4f7f0.toInt()))
        // group mark
        c.drawCircle(110f,136f,12f,paint(green)); c.drawCircle(85f,143f,9f,paint(green)); c.drawCircle(135f,143f,9f,paint(green))
        c.drawOval(78f,151f,142f,184f,paint(green)); c.drawOval(58f,159f,92f,184f,paint(green)); c.drawOval(128f,159f,162f,184f,paint(green))
        c.drawLine(215f,106f,215f,208f,paint(0xffaab9ad.toInt()))
        text(c,"हमारा समूह",250f,153f,43f,ink,true)
        text(c,"साथ मिलकर, आगे बढ़ें...",250f,198f,28f,ink,false)
        rounded(c,731f,106f,819f,197f,28f,white,true)
        text(c,"♟",775f,164f,39f,green,true,Paint.Align.CENTER)
        c.drawCircle(801f,121f,7f,paint(0xffe74b45.toInt()))
    }
    private fun drawHero(c:Canvas){
        val l=28f; val t=258f; val r=838f; val b=439f
        val q=paint(green); q.shader=LinearGradient(l,t,r,b,0xff496e5d.toInt(),0xff183e32.toInt(),Shader.TileMode.CLAMP); q.setShadowLayer(18f,0f,10f,0x330c241b.toInt()); c.drawRoundRect(l,t,r,b,39f,39f,q); q.shader=null; q.clearShadowLayer()
        c.drawLine(415f,305f,415f,394f,paint(0x88dce8df.toInt()).apply{strokeWidth=1.5f})
        drawPeople(c,128f,348f,Color.WHITE,1.05f)
        text(c,"48",205f,351f,54f,Color.WHITE,true); text(c,"कुल सदस्य",205f,393f,29f,0xfff0f5ef.toInt())
        drawHandshake(c,500f,348f)
        text(c,"₹1,25,000",584f,351f,48f,Color.WHITE,true); text(c,"कुल वितरित ऋण",584f,393f,29f,0xfff0f5ef.toInt())
    }
    private fun drawStats(c:Canvas){
        gradientCard(c,28f,468f,419f,611f,38f,0xfffcfdf9.toInt(),0xffe7eee6.toInt())
        gradientCard(c,445f,468f,838f,611f,38f,0xfffcfdf9.toInt(),0xffe7eee6.toInt())
        drawWallet(c,100f,540f); text(c,"₹72,000",171f,537f,43f,ink,true); text(c,"कुल प्राप्त राशि",171f,581f,29f)
        drawClock(c,540f,540f); text(c,"₹28,000",596f,537f,43f,ink,true); text(c,"बकाया राशि",596f,581f,29f)
    }
    private fun drawActions(c:Canvas){
        val xs=listOf(31f,246f,447f,655f); val ws=listOf(190f,181f,184f,183f)
        for(i in xs.indices) gradientCard(c,xs[i],647f,xs[i]+ws[i],849f,37f,0xfffcfdf9.toInt(),0xffe7eee6.toInt())
        // plus
        c.drawCircle(128f,711f,32f,paint(green)); c.drawLine(128f,694f,128f,728f,paint(Color.WHITE).apply{strokeWidth=5f;strokeCap=Paint.Cap.ROUND}); c.drawLine(111f,711f,145f,711f,paint(Color.WHITE).apply{strokeWidth=5f;strokeCap=Paint.Cap.ROUND})
        drawPeople(c,337f,711f,green,0.75f); drawLedger(c,541f,711f); drawDownload(c,747f,711f)
        text(c,"नया ऋण",126f,790f,27f,ink,false,Paint.Align.CENTER); text(c,"दें",126f,823f,27f,ink,false,Paint.Align.CENTER)
        text(c,"सदस्य प्रबंधन",337f,790f,25f,ink,false,Paint.Align.CENTER)
        text(c,"लेन-देन",539f,790f,27f,ink,false,Paint.Align.CENTER); text(c,"देखें",539f,823f,27f,ink,false,Paint.Align.CENTER)
        text(c,"स्टेटमेंट",746f,790f,27f,ink,false,Paint.Align.CENTER); text(c,"बनाएं",746f,823f,27f,ink,false,Paint.Align.CENTER)
    }
    private fun drawActivity(c:Canvas){
        gradientCard(c,28f,885f,838f,1334f,40f,0xfffcfdf9.toInt(),0xffeef2eb.toInt())
        text(c,"हाल की गतिविधियां",58f,950f,39f,ink,true); text(c,"सभी देखें  ›",666f,950f,28f,ink,true)
        c.drawLine(59f,978f,807f,978f,paint(0x557b8c7d.toInt()))
        activityRow(c,1037f,"प्रवीण को ऋण दिया गया","₹10,000 • 07/07/2025","देय",0)
        c.drawLine(60f,1097f,807f,1097f,paint(0x557b8c7d.toInt()))
        activityRow(c,1152f,"सीमा का भुगतान प्राप्त हुआ","₹5,000 • 05/07/2025","भुगतान",1)
        c.drawLine(60f,1213f,807f,1213f,paint(0x557b8c7d.toInt()))
        activityRow(c,1268f,"रमेश को ऋण दिया गया","₹5,000 • 01/07/2025","देय",2)
    }
    private fun activityRow(c:Canvas,y:Float,title:String,sub:String,status:String,type:Int){
        c.drawCircle(114f,y,47f,paint(0xffe0ebe1.toInt())); c.drawCircle(114f,y,34f,paint(0xffc9ddd0.toInt()))
        when(type){1->{text(c,"✓",114f,y+13f,40f,green,true,Paint.Align.CENTER)};else->{text(c,"₹",114f,y+10f,30f,green,true,Paint.Align.CENTER); c.drawLine(93f,y+20f,135f,y+20f,paint(green).apply{strokeWidth=3f})}}
        text(c,title,191f,y-5f,29f,ink,true); text(c,sub,191f,y+36f,25f,0xff34463e.toInt())
        rounded(c,706f,y-29f,807f,y+27f,28f,0xffdcebdc.toInt()); text(c,status,756f,y+9f,24f,0xff315d49.toInt(),true,Paint.Align.CENTER)
    }
    private fun drawBottomNav(c:Canvas){
        gradientCard(c,28f,1364f,838f,1498f,39f,0xfffcfdf9.toInt(),0xffe5ece4.toInt())
        rounded(c,76f,1380f,203f,1447f,36f,0xff285844.toInt(),true)
        // home icon
        val roof=Path().apply{moveTo(112f,1410f);lineTo(139f,1388f);lineTo(166f,1410f);lineTo(160f,1410f);lineTo(160f,1434f);lineTo(144f,1434f);lineTo(144f,1419f);lineTo(134f,1419f);lineTo(134f,1434f);lineTo(118f,1434f);lineTo(118f,1410f);close()}; c.drawPath(roof,paint(Color.WHITE))
        drawPeople(c,338f,1410f,green,0.72f); drawWallet(c,541f,1410f); drawLedger(c,737f,1410f)
        text(c,"होम",139f,1475f,27f,ink,true,Paint.Align.CENTER); text(c,"सदस्य",338f,1475f,27f,ink,false,Paint.Align.CENTER); text(c,"लेन-देन",541f,1475f,27f,ink,false,Paint.Align.CENTER); text(c,"स्टेटमेंट",737f,1475f,27f,ink,false,Paint.Align.CENTER)
        rounded(c,83f,1490f,195f,1497f,4f,green)
    }
    private fun drawPeople(c:Canvas,x:Float,y:Float,color:Int,k:Float){
        c.drawCircle(x,y-18*k,11*k,paint(color)); c.drawCircle(x-25*k,y-12*k,9*k,paint(color)); c.drawCircle(x+25*k,y-12*k,9*k,paint(color))
        c.drawOval(x-19*k,y-5*k,x+19*k,y+24*k,paint(color)); c.drawOval(x-48*k,y+1*k,x-18*k,y+23*k,paint(color)); c.drawOval(x+18*k,y+1*k,x+48*k,y+23*k,paint(color))
    }
    private fun drawWallet(c:Canvas,x:Float,y:Float){
        val q=paint(green); c.drawRoundRect(x-28,y-26,x+26,y+25,8f,8f,q); c.drawRoundRect(x-20,y-34,x+20,y-25,5f,5f,q); c.drawRoundRect(x+5,y-8,x+37,y+13,7f,7f,q); c.drawCircle(x+18,y+2,3f,paint(Color.WHITE))
    }
    private fun drawClock(c:Canvas,x:Float,y:Float){c.drawCircle(x,y,32f,paint(green)); c.drawLine(x,y,x,y-18,paint(Color.WHITE).apply{strokeWidth=4f;strokeCap=Paint.Cap.ROUND}); c.drawLine(x,y,x+15,y+10,paint(Color.WHITE).apply{strokeWidth=4f;strokeCap=Paint.Cap.ROUND}); c.drawArc(x-40,y-40,x+40,y+40,210f,115f,false,paint(green).apply{style=Paint.Style.STROKE;strokeWidth=5f})}
    private fun drawLedger(c:Canvas,x:Float,y:Float){rounded(c,x-24,y-32,x+24,y+31,6f,green); for(i in 0..2)c.drawLine(x-11,y-12+i*15,x+13,y-12+i*15,paint(Color.WHITE).apply{strokeWidth=3f})}
    private fun drawDownload(c:Canvas,x:Float,y:Float){rounded(c,x-25,y-32,x+25,y+31,5f,green); val path=Path().apply{moveTo(x,y-18);lineTo(x,y+9);moveTo(x-12,y-2);lineTo(x,y+10);lineTo(x+12,y-2)}; c.drawPath(path,paint(Color.WHITE).apply{style=Paint.Style.STROKE;strokeWidth=4f;strokeCap=Paint.Cap.ROUND;strokeJoin=Paint.Join.ROUND})}
    private fun drawHandshake(c:Canvas,x:Float,y:Float){val q=paint(Color.WHITE); q.strokeWidth=8f;q.strokeCap=Paint.Cap.ROUND; c.drawLine(x-30,y-16,x-9,y-5,q);c.drawLine(x-9,y-5,x+6,y-19,q);c.drawLine(x+6,y-19,x+27,y-5,q);c.drawLine(x-9,y-5,x+10,y+17,q);c.drawLine(x+10,y+17,x+30,y-3,q);c.drawLine(x-27,y+4,x-7,y+25,q)}
}
