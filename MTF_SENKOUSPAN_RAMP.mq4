//+------------------------------------------------------------------+
//|                                          MTF_SENKOUSPAN_RAMP.mq4 |
//|                                      Copyright 2019, 崩れかけた家 |
//|                            https://discordapp.com/invite/N9PMEym |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, 崩れかけた家"
#property link "https://discordapp.com/invite/N9PMEym"
#property version "1.00"
#property strict

//-----インジゲーター設定------
// 表示場所
#property indicator_chart_window
// #property indicator_separate_window
// 先行スパンA
#property indicator_color1 clrAqua
#property indicator_width1 1
#property indicator_type1 DRAW_LINE

// 先行スパンB
#property indicator_color2 clrAqua
#property indicator_width2 1
#property indicator_type2 DRAW_LINE

// 上昇塗りつぶし用
#property indicator_type3 DRAW_HISTOGRAM
#property indicator_color3 clrAqua
#property indicator_style3 STYLE_DOT
#property indicator_width3 1

// 下降塗りつぶし用
#property indicator_type4 DRAW_HISTOGRAM
#property indicator_color4 clrRed
#property indicator_style4 STYLE_DOT
#property indicator_width4 1
//---------------------------

//--------ENUM定義-----------
// Pascal方式
// MA算出方式
enum TaMethodList
{
   SMA = 0,  // 単純移動平均線
   EMA = 1,  // 指数移動平均線
   SMMA = 2, // 平滑移動平均線
   LWMA = 3  // 線形加重移動平均戦
};
// チャート時間軸
enum TimeFrameList
{
   Current_timeFrame = 0, // 現在の時間足
   M1 = 1,                // 1分足
   M5 = 5,                // 5分足
   M15 = 15,              // 15分足
   M30 = 30,              // 30分足
   H1 = 60,               // 1時間足
   H4 = 240,              // 4時間足
   D1 = 1440,             // 日足
   W1 = 10080,            //週足
   MN = 43200             // 月足
};
// 価格データ
enum AppliedPriceList
{
   CLOSE = 0,   // 終値
   OPEN = 1,    // 始値
   HIGH = 2,    // 高値
   LOW = 3,     // 安値
   MEDIAN = 4,  // 中央値
   TYPICAL = 5, // 代表値
   WEIGHTED = 6 // 加重終値
};
//---------------------------

//------パラメーター定義------
// Pascal方式
// MTF用
int MtfTimeFrameId;
extern TimeFrameList MtfTimeFrame = Current_timeFrame; // MTFで表示させる時間軸
extern int TenkanSenPeriod = 9;                        // 転換線期間
extern int KijunSenPeriod = 26;                        // 基準線期間
extern int SenkouSupanPeriod = 52;                     // 先行スパン期間

//---------------------------

//-------変数・定数定義-------
// Camel方式
// アラート重複排除用
datetime b4Time;
//---------------------------

//----------配列定義---------
// Camel方式
double senkouSpanA[], senkouSpanB[], upTrend[], downTrend[];
//---------------------------

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0, senkouSpanA);
   SetIndexShift(0, KijunSenPeriod);
   SetIndexBuffer(1, senkouSpanB);
   SetIndexShift(1, KijunSenPeriod);
   SetIndexBuffer(2, upTrend);
   SetIndexShift(2, KijunSenPeriod);
   SetIndexBuffer(3, downTrend);
   SetIndexShift(3, KijunSenPeriod);

   ObjectsDeleteAll();

   ObjectCreate(0, "5m", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "5m", OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, "5m", OBJPROP_XDISTANCE, 30);
   ObjectSetInteger(0, "5m", OBJPROP_YDISTANCE, 30);
   ObjectSetInteger(0, "5m", OBJPROP_XSIZE, 100);
   ObjectSetInteger(0, "5m", OBJPROP_YSIZE, 50);
   ObjectSetInteger(0, "5m", OBJPROP_BGCOLOR, clrBlue);
   ObjectSetInteger(0, "5m", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, "5m", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "5m", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "5m", OBJPROP_WIDTH, 5);

   ObjectCreate(0, "5m_char", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "5m_char", OBJPROP_XDISTANCE, 60);
   ObjectSetInteger(0, "5m_char", OBJPROP_YDISTANCE, 45);
   ObjectSetText("5m_char", "5m", 18, "ＭＳ　ゴシック", White);

   ObjectCreate(0, "15m", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "15m", OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, "15m", OBJPROP_XDISTANCE, 30);
   ObjectSetInteger(0, "15m", OBJPROP_YDISTANCE, 80);
   ObjectSetInteger(0, "15m", OBJPROP_XSIZE, 100);
   ObjectSetInteger(0, "15m", OBJPROP_YSIZE, 50);
   ObjectSetInteger(0, "15m", OBJPROP_BGCOLOR, clrBlue);
   ObjectSetInteger(0, "15m", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, "15m", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "15m", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "15m", OBJPROP_WIDTH, 5);

   ObjectCreate(0, "15m_char", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "15m_char", OBJPROP_XDISTANCE, 60);
   ObjectSetInteger(0, "15m_char", OBJPROP_YDISTANCE, 95);
   ObjectSetText("15m_char", "15m", 18, "ＭＳ　ゴシック", White);

   ObjectCreate(0, "30m", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "30m", OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, "30m", OBJPROP_XDISTANCE, 30);
   ObjectSetInteger(0, "30m", OBJPROP_YDISTANCE, 130);
   ObjectSetInteger(0, "30m", OBJPROP_XSIZE, 100);
   ObjectSetInteger(0, "30m", OBJPROP_YSIZE, 50);
   ObjectSetInteger(0, "30m", OBJPROP_BGCOLOR, clrBlue);
   ObjectSetInteger(0, "30m", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, "30m", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "30m", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "30m", OBJPROP_WIDTH, 5);

   ObjectCreate(0, "30m_char", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "30m_char", OBJPROP_XDISTANCE, 60);
   ObjectSetInteger(0, "30m_char", OBJPROP_YDISTANCE, 145);
   ObjectSetText("30m_char", "30m", 18, "ＭＳ　ゴシック", White);

   ObjectCreate(0, "60m", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "60m", OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, "60m", OBJPROP_XDISTANCE, 30);
   ObjectSetInteger(0, "60m", OBJPROP_YDISTANCE, 180);
   ObjectSetInteger(0, "60m", OBJPROP_XSIZE, 100);
   ObjectSetInteger(0, "60m", OBJPROP_YSIZE, 50);
   ObjectSetInteger(0, "60m", OBJPROP_BGCOLOR, clrBlue);
   ObjectSetInteger(0, "60m", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, "60m", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "60m", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "60m", OBJPROP_WIDTH, 5);

   ObjectCreate(0, "60m_char", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "60m_char", OBJPROP_XDISTANCE, 60);
   ObjectSetInteger(0, "60m_char", OBJPROP_YDISTANCE, 195);
   ObjectSetText("60m_char", "60m", 18, "ＭＳ　ゴシック", White);

   ObjectCreate(0, "5m_sign", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "5m_sign", OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, "5m_sign", OBJPROP_XDISTANCE, 130);
   ObjectSetInteger(0, "5m_sign", OBJPROP_YDISTANCE, 30);
   ObjectSetInteger(0, "5m_sign", OBJPROP_XSIZE, 100);
   ObjectSetInteger(0, "5m_sign", OBJPROP_YSIZE, 50);
   ObjectSetInteger(0, "5m_sign", OBJPROP_BGCOLOR, clrBlack);
   ObjectSetInteger(0, "5m_sign", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, "5m_sign", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "5m_sign", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "5m_sign", OBJPROP_WIDTH, 5);

   ObjectCreate(0, "15m_sign", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "15m_sign", OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, "15m_sign", OBJPROP_XDISTANCE, 130);
   ObjectSetInteger(0, "15m_sign", OBJPROP_YDISTANCE, 80);
   ObjectSetInteger(0, "15m_sign", OBJPROP_XSIZE, 100);
   ObjectSetInteger(0, "15m_sign", OBJPROP_YSIZE, 50);
   ObjectSetInteger(0, "15m_sign", OBJPROP_BGCOLOR, clrBlack);
   ObjectSetInteger(0, "15m_sign", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, "15m_sign", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "15m_sign", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "15m_sign", OBJPROP_WIDTH, 5);

   ObjectCreate(0, "30m_sign", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "30m_sign", OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, "30m_sign", OBJPROP_XDISTANCE, 130);
   ObjectSetInteger(0, "30m_sign", OBJPROP_YDISTANCE, 130);
   ObjectSetInteger(0, "30m_sign", OBJPROP_XSIZE, 100);
   ObjectSetInteger(0, "30m_sign", OBJPROP_YSIZE, 50);
   ObjectSetInteger(0, "30m_sign", OBJPROP_BGCOLOR, clrBlack);
   ObjectSetInteger(0, "30m_sign", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, "30m_sign", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "30m_sign", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "30m_sign", OBJPROP_WIDTH, 5);

   ObjectCreate(0, "60m_sign", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "60m_sign", OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, "60m_sign", OBJPROP_XDISTANCE, 130);
   ObjectSetInteger(0, "60m_sign", OBJPROP_YDISTANCE, 180);
   ObjectSetInteger(0, "60m_sign", OBJPROP_XSIZE, 100);
   ObjectSetInteger(0, "60m_sign", OBJPROP_YSIZE, 50);
   ObjectSetInteger(0, "60m_sign", OBJPROP_BGCOLOR, clrBlack);
   ObjectSetInteger(0, "60m_sign", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, "60m_sign", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "60m_sign", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "60m_sign", OBJPROP_WIDTH, 5);
   // for (int i = 0; i < 4; i++)
   // {
   //    string displayTimeFrame;
   //    int i = 0;
   //    int yDistance = 30 + (i + 1) * 50;
   //    switch (i)
   //    {
   //    case 0:
   //       displayTimeFrame = "5m";
   //       break;
   //    case 1:
   //       displayTimeFrame = "15m";
   //       break;
   //    case 2:
   //       displayTimeFrame = "30m";
   //       break;
   //    case 3:
   //       displayTimeFrame = "60m";
   //       break;
   //    }
   //    ObjectCreate(i, displayTimeFrame, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   //    ObjectSetInteger(i, displayTimeFrame, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   //    ObjectSetInteger(i, displayTimeFrame, OBJPROP_XDISTANCE, 30);
   //    ObjectSetInteger(i, displayTimeFrame, OBJPROP_YDISTANCE, yDistance);
   //    ObjectSetInteger(i, displayTimeFrame, OBJPROP_XSIZE, 100);
   //    ObjectSetInteger(i, displayTimeFrame, OBJPROP_YSIZE, 50);
   //    ObjectSetInteger(i, displayTimeFrame, OBJPROP_BGCOLOR, clrBlue);
   //    ObjectSetInteger(i, displayTimeFrame, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   //    ObjectSetInteger(i, displayTimeFrame, OBJPROP_COLOR, clrWhite);
   //    ObjectSetInteger(i, displayTimeFrame, OBJPROP_STYLE, STYLE_SOLID);
   //    ObjectSetInteger(i, displayTimeFrame, OBJPROP_WIDTH, 5);
   // }
   MtfTimeFrameId = MtfTimeFrame;
   return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll();
}
//+------------------------------------------------------------------+
//| Custom indicator start function                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   // ループ上限
   int limit = Bars - IndicatorCounted();
   // 足が更新されたかの判定
   bool isNewCandle = Time[0] != b4Time && limit == 2;

   for (int i = limit - 1; i >= 0 && !IsStopped(); i--)
   {
      //インジ計算処理
      int shift = iBarShift(NULL, MtfTimeFrameId, time[i], false);
      upTrend[i] = senkouSpanA[i] = iIchimoku(NULL, MtfTimeFrameId, TenkanSenPeriod, KijunSenPeriod, SenkouSupanPeriod, 3, i);
      downTrend[i] = senkouSpanB[i] = iIchimoku(NULL, MtfTimeFrameId, TenkanSenPeriod, KijunSenPeriod, SenkouSupanPeriod, 4, i);
   }
   double senkouSpanA5m = iIchimoku(NULL, 5, TenkanSenPeriod, KijunSenPeriod, SenkouSupanPeriod, MODE_SENKOUSPANA, 0);
   double senkouSpanB5m = iIchimoku(NULL, 5, TenkanSenPeriod, KijunSenPeriod, SenkouSupanPeriod, MODE_SENKOUSPANB, 0);

   if (senkouSpanA5m > senkouSpanB5m)
   {
      ObjectDelete(0, "5m_arrow");
      ObjectCreate(0, "5m_arrow", OBJ_LABEL, 0, 0, 0, 0, 0);
      ObjectSetInteger(0, "5m_arrow", OBJPROP_XDISTANCE, 165);
      ObjectSetInteger(0, "5m_arrow", OBJPROP_YDISTANCE, 35);
      ObjectSetText("5m_arrow", CharToStr(221), 30, "Wingdings", DeepSkyBlue);
   }
   if (senkouSpanA5m < senkouSpanB5m)
   {
      ObjectDelete(0, "5m_arrow");
      ObjectCreate(0, "5m_arrow", OBJ_LABEL, 0, 0, 0, 0, 0);
      ObjectSetInteger(0, "5m_arrow", OBJPROP_XDISTANCE, 165);
      ObjectSetInteger(0, "5m_arrow", OBJPROP_YDISTANCE, 35);
      ObjectSetText("5m_arrow", CharToStr(222), 30, "Wingdings", Red);
   }

   double senkouSpanA15m = iIchimoku(NULL, 15, TenkanSenPeriod, KijunSenPeriod, SenkouSupanPeriod, MODE_SENKOUSPANA, 0);
   double senkouSpanB15m = iIchimoku(NULL, 15, TenkanSenPeriod, KijunSenPeriod, SenkouSupanPeriod, MODE_SENKOUSPANB, 0);

   if (senkouSpanA15m > senkouSpanB15m)
   {
      ObjectDelete(0, "15m_arrow");
      ObjectCreate(0, "15m_arrow", OBJ_LABEL, 0, 0, 0, 0, 0);
      ObjectSetInteger(0, "15m_arrow", OBJPROP_XDISTANCE, 165);
      ObjectSetInteger(0, "15m_arrow", OBJPROP_YDISTANCE, 85);
      ObjectSetText("15m_arrow", CharToStr(221), 30, "Wingdings", DeepSkyBlue);
   }
   if (senkouSpanA15m < senkouSpanB15m)
   {
      ObjectDelete(0, "15m_arrow");
      ObjectCreate(0, "15m_arrow", OBJ_LABEL, 0, 0, 0, 0, 0);
      ObjectSetInteger(0, "15m_arrow", OBJPROP_XDISTANCE, 165);
      ObjectSetInteger(0, "15m_arrow", OBJPROP_YDISTANCE, 85);
      ObjectSetText("15m_arrow", CharToStr(222), 30, "Wingdings", Red);
   }

   double senkouSpanA30m = iIchimoku(NULL, 30, TenkanSenPeriod, KijunSenPeriod, SenkouSupanPeriod, MODE_SENKOUSPANA, 0);
   double senkouSpanB30m = iIchimoku(NULL, 30, TenkanSenPeriod, KijunSenPeriod, SenkouSupanPeriod, MODE_SENKOUSPANB, 0);

   if (senkouSpanA30m > senkouSpanB30m)
   {
      ObjectDelete(0, "30m_arrow");
      ObjectCreate(0, "30m_arrow", OBJ_LABEL, 0, 0, 0, 0, 0);
      ObjectSetInteger(0, "30m_arrow", OBJPROP_XDISTANCE, 165);
      ObjectSetInteger(0, "30m_arrow", OBJPROP_YDISTANCE, 135);
      ObjectSetText("30m_arrow", CharToStr(221), 30, "Wingdings", DeepSkyBlue);
   }
   if (senkouSpanA30m < senkouSpanB30m)
   {
      ObjectDelete(0, "30m_arrow");
      ObjectCreate(0, "30m_arrow", OBJ_LABEL, 0, 0, 0, 0, 0);
      ObjectSetInteger(0, "30m_arrow", OBJPROP_XDISTANCE, 165);
      ObjectSetInteger(0, "30m_arrow", OBJPROP_YDISTANCE, 135);
      ObjectSetText("30m_arrow", CharToStr(222), 30, "Wingdings", Red);
   }

   double senkouSpanA60m = iIchimoku(NULL, 60, TenkanSenPeriod, KijunSenPeriod, SenkouSupanPeriod, MODE_SENKOUSPANA, 0);
   double senkouSpanB60m = iIchimoku(NULL, 60, TenkanSenPeriod, KijunSenPeriod, SenkouSupanPeriod, MODE_SENKOUSPANB, 0);

   if (senkouSpanA60m > senkouSpanB60m)
   {
      ObjectDelete(0, "60m_arrow");
      ObjectCreate(0, "60m_arrow", OBJ_LABEL, 0, 0, 0, 0, 0);
      ObjectSetInteger(0, "60m_arrow", OBJPROP_XDISTANCE, 165);
      ObjectSetInteger(0, "60m_arrow", OBJPROP_YDISTANCE, 185);
      ObjectSetText("60m_arrow", CharToStr(221), 30, "Wingdings", DeepSkyBlue);
   }
   if (senkouSpanA60m < senkouSpanB60m)
   {
      ObjectDelete(0, "60m_arrow");
      ObjectCreate(0, "60m_arrow", OBJ_LABEL, 0, 0, 0, 0, 0);
      ObjectSetInteger(0, "60m_arrow", OBJPROP_XDISTANCE, 165);
      ObjectSetInteger(0, "60m_arrow", OBJPROP_YDISTANCE, 185);
      ObjectSetText("60m_arrow", CharToStr(222), 30, "Wingdings", Red);
   }
   // if (isNewCandle && (senkouSpanA[i + 1] < senkouSpanB[i + 1] && senkouSpanA[i] >= senkouSpanB[i]))
   // {
   //    Alert(Symbol() + MtfTimeFrameId + "GC");
   // }
   // if (isNewCandle && (senkouSpanB[i + 1] < senkouSpanA[i + 1] && senkouSpanB[i] >= senkouSpanA[i]))
   // {
   //    Alert(Symbol() + MtfTimeFrameId + "DC");
   // }
   b4Time = Time[0];

   return (rates_total);
}
