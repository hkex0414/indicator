//+------------------------------------------------------------------+
//|                                      MTF_SENKOUSPAN_HISTGRAM.mq4 |
//|                                      Copyright 2019, 崩れかけた家 |
//|                            https://discordapp.com/invite/N9PMEym |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, 崩れかけた家"
#property link "https://discordapp.com/invite/N9PMEym"
#property version "1.00"
#property strict

//-----インジゲーター設定------
// 表示場所
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_color1 LimeGreen
#property indicator_color2 Red
#property indicator_color3 Gold
#property indicator_width1 3
#property indicator_width2 3
#property indicator_width3 3
#property indicator_minimum 0
#property indicator_maximum 1
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
   MN = 43200,            // 月足
   returnBars = 100,      // 再帰処理用（選択禁止）
   calculateValue = 200   // 再帰処理用（選択禁止）
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
extern TimeFrameList TimeFrame = Current_timeFrame; // MTFで表示させる時間軸
extern int Tenkan = 9;                              // 転換線期間
extern int Kijun = 26;                              // 基準線期間
extern int Senkou = 52;                             // 先行スパン期間

extern bool alertsOn = true;

//---------------------------

//-------変数・定数定義-------
// Camel方式
// アラート重複排除用
datetime b4Time;
string indicatorFileName;
int timeFrame;
bool returnBars;
bool calculateValue;
int whichBar;
//---------------------------

//----------配列定義---------
// Camel方式
double UpH[];
double DnH[];
double NuH[];
double Tenkan_Buffer[];
double Kijun_Buffer[];
double SpanA_Buffer[];
double SpanB_Buffer[];
double trend[];
//---------------------------

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   MtfTimeFrameId = TimeFrame;
   IndicatorBuffers(8);
   SetIndexBuffer(0, UpH);
   SetIndexStyle(0, DRAW_HISTOGRAM);
   SetIndexBuffer(1, DnH);
   SetIndexStyle(1, DRAW_HISTOGRAM);
   SetIndexBuffer(2, NuH);
   SetIndexStyle(2, DRAW_HISTOGRAM);
   SetIndexBuffer(3, Tenkan_Buffer);
   SetIndexBuffer(4, Kijun_Buffer);
   SetIndexBuffer(5, SpanA_Buffer);
   SetIndexBuffer(6, SpanB_Buffer);
   SetIndexBuffer(7, trend);

   indicatorFileName = WindowExpertName();
   calculateValue = (MtfTimeFrameId == 100);
   if (calculateValue)
      return (0);
   returnBars = (MtfTimeFrameId == 200);
   if (returnBars)
      return (0);
   MtfTimeFrameId = stringToTimeFrame(MtfTimeFrameId);
   SetIndexShift(0, Kijun * MtfTimeFrameId / Period());
   SetIndexShift(1, Kijun * MtfTimeFrameId / Period());
   SetIndexShift(2, Kijun * MtfTimeFrameId / Period());
   SetIndexShift(5, Kijun * MtfTimeFrameId / Period());
   SetIndexShift(6, Kijun * MtfTimeFrameId / Period());
   IndicatorShortName(timeFrameToString(MtfTimeFrameId) + "  SpanA-SpanB Cross Histo");

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

   return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
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
   int counted_bars = IndicatorCounted();
   int i, k, limit;

   if (counted_bars < 0)
      return (-1);
   if (counted_bars > 0)
      counted_bars--;
   limit = MathMin(Bars - counted_bars, Bars - 1);
   if (returnBars)
   {
      UpH[0] = limit + 1;
      return (0);
   }

   //
   //
   //
   //
   //

   if (calculateValue || MtfTimeFrameId == Period())
   {
      for (i = limit; i >= 0; i--)
      {

         double thi = High[i];
         double tlo = Low[i];
         double tprice = 0;
         if (i >= Bars - Tenkan)
            continue;
         for (k = 0; k < Tenkan; k++)
         {
            tprice = High[i + k];
            if (thi < tprice)
               thi = tprice;

            tprice = Low[i + k];
            if (tlo > tprice)
               tlo = tprice;
         }

         if ((thi + tlo) > 0.0)
            Tenkan_Buffer[i] = (thi + tlo) / 2;
         else
            Tenkan_Buffer[i] = 0;

         //
         //
         //
         //
         //

         double khi = High[i];
         double klo = Low[i];
         double kprice = 0;
         if (i >= Bars - Kijun)
            continue;
         for (k = 0; k < Kijun; k++)
         {
            kprice = High[i + k];
            if (khi < kprice)
               khi = kprice;

            kprice = Low[i + k];
            if (klo > kprice)
               klo = kprice;
         }

         if ((khi + klo) > 0.0)
            Kijun_Buffer[i] = (khi + klo) / 2;
         else
            Kijun_Buffer[i] = 0;

         //
         //
         //
         //
         //

         double shi = High[i];
         double slo = Low[i];
         double sprice = 0;
         if (i >= Bars - Senkou)
            continue;
         for (k = 0; k < Senkou; k++)
         {
            sprice = High[i + k];
            if (shi < sprice)
               shi = sprice;

            sprice = Low[i + k];
            if (slo > sprice)
               slo = sprice;
         }

         SpanA_Buffer[i] = (Kijun_Buffer[i] + Tenkan_Buffer[i]) * 0.5;
         SpanB_Buffer[i] = (shi + slo) * 0.5;

         //
         //
         //
         //
         //

         UpH[i] = EMPTY_VALUE;
         DnH[i] = EMPTY_VALUE;
         NuH[i] = EMPTY_VALUE;

         trend[i] = trend[i + 1];

         if (SpanA_Buffer[i] > SpanB_Buffer[i])
            trend[i] = 1;

         if (SpanA_Buffer[i] < SpanB_Buffer[i])
            trend[i] = -1;
         if (SpanA_Buffer[i] == SpanB_Buffer[i])
            trend[i] = 0;
         if (trend[i] == 1)
            UpH[i] = 1;
         if (trend[i] == -1)
            DnH[i] = 1;
         if (trend[i] == 0)
            NuH[i] = 1;
      }
      manageAlerts();
      createArrowObject();

      return (0);
   }

   //
   //
   //
   //
   //

   limit = MathMax(limit, MathMin(Bars - 1, iCustom(NULL, MtfTimeFrameId, indicatorFileName, "returnBars", 0, 0) * MtfTimeFrameId / Period()));
   for (i = limit; i >= 0; i--)
   {
      int y = iBarShift(NULL, MtfTimeFrameId, Time[i]);
      trend[i] = iCustom(NULL, MtfTimeFrameId, indicatorFileName, "calculateValue", Tenkan, Kijun, Senkou, 7, y);
      UpH[i] = EMPTY_VALUE;
      DnH[i] = EMPTY_VALUE;
      NuH[i] = EMPTY_VALUE;

      if (trend[i] == 1)
         UpH[i] = 1;
      if (trend[i] == -1)
         DnH[i] = 1;
      if (trend[i] == 0)
         NuH[i] = 1;
   }
   manageAlerts();

   // double senkouSpanA15m = iIchimoku(NULL, 15, TenkanSenPeriod, KijunSenPeriod, SenkouSupanPeriod, MODE_SENKOUSPANA, 0);
   // double senkouSpanB15m = iIchimoku(NULL, 15, TenkanSenPeriod, KijunSenPeriod, SenkouSupanPeriod, MODE_SENKOUSPANB, 0);

   // if (senkouSpanA15m > senkouSpanB15m)
   // {
   //    ObjectDelete(0, "15m_arrow");
   //    ObjectCreate(0, "15m_arrow", OBJ_LABEL, 0, 0, 0, 0, 0);
   //    ObjectSetInteger(0, "15m_arrow", OBJPROP_XDISTANCE, 165);
   //    ObjectSetInteger(0, "15m_arrow", OBJPROP_YDISTANCE, 85);
   //    ObjectSetText("15m_arrow", CharToStr(221), 30, "Wingdings", DeepSkyBlue);
   // }
   // if (senkouSpanA15m < senkouSpanB15m)
   // {
   //    ObjectDelete(0, "15m_arrow");
   //    ObjectCreate(0, "15m_arrow", OBJ_LABEL, 0, 0, 0, 0, 0);
   //    ObjectSetInteger(0, "15m_arrow", OBJPROP_XDISTANCE, 165);
   //    ObjectSetInteger(0, "15m_arrow", OBJPROP_YDISTANCE, 85);
   //    ObjectSetText("15m_arrow", CharToStr(222), 30, "Wingdings", Red);
   // }

   // double senkouSpanA30m = iIchimoku(NULL, 30, TenkanSenPeriod, KijunSenPeriod, SenkouSupanPeriod, MODE_SENKOUSPANA, 0);
   // double senkouSpanB30m = iIchimoku(NULL, 30, TenkanSenPeriod, KijunSenPeriod, SenkouSupanPeriod, MODE_SENKOUSPANB, 0);

   // if (senkouSpanA30m > senkouSpanB30m)
   // {
   //    ObjectDelete(0, "30m_arrow");
   //    ObjectCreate(0, "30m_arrow", OBJ_LABEL, 0, 0, 0, 0, 0);
   //    ObjectSetInteger(0, "30m_arrow", OBJPROP_XDISTANCE, 165);
   //    ObjectSetInteger(0, "30m_arrow", OBJPROP_YDISTANCE, 135);
   //    ObjectSetText("30m_arrow", CharToStr(221), 30, "Wingdings", DeepSkyBlue);
   // }
   // if (senkouSpanA30m < senkouSpanB30m)
   // {
   //    ObjectDelete(0, "30m_arrow");
   //    ObjectCreate(0, "30m_arrow", OBJ_LABEL, 0, 0, 0, 0, 0);
   //    ObjectSetInteger(0, "30m_arrow", OBJPROP_XDISTANCE, 165);
   //    ObjectSetInteger(0, "30m_arrow", OBJPROP_YDISTANCE, 135);
   //    ObjectSetText("30m_arrow", CharToStr(222), 30, "Wingdings", Red);
   // }

   // double senkouSpanA60m = iIchimoku(NULL, 60, TenkanSenPeriod, KijunSenPeriod, SenkouSupanPeriod, MODE_SENKOUSPANA, 0);
   // double senkouSpanB60m = iIchimoku(NULL, 60, TenkanSenPeriod, KijunSenPeriod, SenkouSupanPeriod, MODE_SENKOUSPANB, 0);

   // if (senkouSpanA60m > senkouSpanB60m)
   // {
   //    ObjectDelete(0, "60m_arrow");
   //    ObjectCreate(0, "60m_arrow", OBJ_LABEL, 0, 0, 0, 0, 0);
   //    ObjectSetInteger(0, "60m_arrow", OBJPROP_XDISTANCE, 165);
   //    ObjectSetInteger(0, "60m_arrow", OBJPROP_YDISTANCE, 185);
   //    ObjectSetText("60m_arrow", CharToStr(221), 30, "Wingdings", DeepSkyBlue);
   // }
   // if (senkouSpanA60m < senkouSpanB60m)
   // {
   //    ObjectDelete(0, "60m_arrow");
   //    ObjectCreate(0, "60m_arrow", OBJ_LABEL, 0, 0, 0, 0, 0);
   //    ObjectSetInteger(0, "60m_arrow", OBJPROP_XDISTANCE, 165);
   //    ObjectSetInteger(0, "60m_arrow", OBJPROP_YDISTANCE, 185);
   //    ObjectSetText("60m_arrow", CharToStr(222), 30, "Wingdings", Red);
   // }

   return (rates_total);
}

//+-------------------------------------------------------------------
//|
//+-------------------------------------------------------------------
//
//
//
//
//

string sTfTable[] = {"M1", "M5", "M15", "M30", "H1", "H4", "D1", "W1", "MN"};
int iTfTable[] = {1, 5, 15, 30, 60, 240, 1440, 10080, 43200};

//
//
//
//
//

int stringToTimeFrame(string tfs)
{
   tfs = stringUpperCase(tfs);
   for (int i = ArraySize(iTfTable) - 1; i >= 0; i--)
      if (tfs == sTfTable[i] || tfs == "" + iTfTable[i])
         return (MathMax(iTfTable[i], Period()));
   return (Period());
}

//
//
//
//
//

string timeFrameToString(int tf)
{
   for (int i = ArraySize(iTfTable) - 1; i >= 0; i--)
      if (tf == iTfTable[i])
         return (sTfTable[i]);
   return ("");
}

//
//
//
//
//

string stringUpperCase(string str)
{
   string s = str;

   for (int length = StringLen(str) - 1; length >= 0; length--)
   {
      int tchar = StringGetChar(s, length);
      if ((tchar > 96 && tchar < 123) || (tchar > 223 && tchar < 256))
         s = StringSetChar(s, length, tchar - 32);
      else if (tchar > -33 && tchar < 0)
         s = StringSetChar(s, length, tchar + 224);
   }
   return (s);
}

//+-------------------------------------------------------------------
//|
//+-------------------------------------------------------------------
//
//
//
//
//

void manageAlerts()
{
   if (!calculateValue && alertsOn)
   {
      whichBar = 1;
      whichBar = iBarShift(NULL, 0, iTime(NULL, timeFrame, whichBar));
      if (trend[whichBar] != trend[whichBar + 1])
      {
         if (trend[whichBar] == 1)
            doAlert(whichBar, "GC");
         if (trend[whichBar] == -1)
            doAlert(whichBar, "DC");
         if (trend[whichBar] == 0)
            doAlert(whichBar, "neutral");
      }
   }
}

//
//
//
//
//

void doAlert(int forBar, string doWhat)
{
   static string previousAlert = "nothing";
   static datetime previousTime;
   string message;

   if (previousAlert != doWhat || previousTime != Time[forBar])
   {
      previousAlert = doWhat;
      previousTime = Time[forBar];

      //
      //
      //
      //
      //

      message = StringConcatenate(Symbol(), " ", timeFrameToString(MtfTimeFrameId) + ":SpanAB ", doWhat);
      Alert(message);
      SendNotification(message);
   }
}

void createArrowObject()
{
   int trendTmp = iCustom(NULL, MtfTimeFrameId, indicatorFileName, "calculateValue", Tenkan, Kijun, Senkou, 7, 0);
   if (trendTmp == 1)
   {
      ObjectDelete(0, "5m_arrow");
      ObjectCreate(0, "5m_arrow", OBJ_LABEL, 0, 0, 0, 0, 0);
      ObjectSetInteger(0, "5m_arrow", OBJPROP_XDISTANCE, 165);
      ObjectSetInteger(0, "5m_arrow", OBJPROP_YDISTANCE, 35);
      ObjectSetText("5m_arrow", CharToStr(221), 30, "Wingdings", DeepSkyBlue);
   }
   if (trendTmp == -1)
   {
      ObjectDelete(0, "5m_arrow");
      ObjectCreate(0, "5m_arrow", OBJ_LABEL, 0, 0, 0, 0, 0);
      ObjectSetInteger(0, "5m_arrow", OBJPROP_XDISTANCE, 165);
      ObjectSetInteger(0, "5m_arrow", OBJPROP_YDISTANCE, 35);
      ObjectSetText("5m_arrow", CharToStr(222), 30, "Wingdings", Red);
   }
   if (trendTmp == 0)
   {
      ObjectDelete(0, "5m_arrow");
      ObjectCreate(0, "5m_arrow", OBJ_LABEL, 0, 0, 0, 0, 0);
      ObjectSetInteger(0, "5m_arrow", OBJPROP_XDISTANCE, 165);
      ObjectSetInteger(0, "5m_arrow", OBJPROP_YDISTANCE, 35);
      ObjectSetText("5m_arrow", CharToStr(220), 30, "Wingdings", Gray);
   }
}