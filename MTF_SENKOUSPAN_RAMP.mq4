//+------------------------------------------------------------------+
//|                                          MTF_SENKOUSPAN_RAMP.mq4 |
//|                                      Copyright 2019, 崩れかけた家 |
//|                            https://discordapp.com/invite/N9PMEym |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, 崩れかけた家"
#property link "https://discordapp.com/invite/N9PMEym"
#property version "1.00"
#property strict

// #property indicator_chart_window
#property indicator_buffers 4
#property indicator_color1 Red
#property indicator_color2 Aqua
#property indicator_color3 Green
#property indicator_color4 Green

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

//---- input parameters
int MtfTimeFrameId;
extern TimeFrameList MtfTimeFrame = Current_timeFrame; // MTFで表示させる時間軸
extern int Tenkan = 9;                                 // 転換線期間
extern int Kijun = 26;                                 // 基準線期間
extern int Senkou = 52;                                // 先行スパン期間
extern bool IsCloud = false;                           // MTF雲表示切り替え
extern bool IsRamp = true;                             // MTFランプ表示切り替え
extern bool IsNotification = true;                     // Push通知切り替え
extern bool IsMailNotification = false;                // メール通知切り替え
extern bool Is5mNotification = true;                   // 5m通知切り替え
extern bool Is15mNotification = true;                  // 15m通知切り替え
extern bool Is30mNotification = true;                  // 30m通知切り替え
extern bool Is60mNotification = true;                  // 1h通知切り替え

//---- buffers
// double Tenkan_Buffer[];
// double Kijun_Buffer[];
double SpanA_Buffer[];
double SpanB_Buffer[];
// double Chinkou_Buffer[];
double SpanA2_Buffer[];
double SpanB2_Buffer[];
int period5Flag = 0;
int period15Flag = 0;
int period30Flag = 0;
int period60Flag = 0;
datetime b4Time = Time[0];
string ObjArray[8] = {"5m_char", "15m_char", "30m_char", "60m_char", "5m_arrow", "15m_arrow", "30m_arrow", "60m_arrow"};

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   MtfTimeFrameId = MtfTimeFrame;
   int k = 1;
   if (MtfTimeFrameId > 0)
      k = MtfTimeFrameId / Period();
   SetIndexStyle(2, DRAW_HISTOGRAM, STYLE_DOT, 1, clrAqua);
   SetIndexBuffer(2, SpanA_Buffer);
   SetIndexShift(2, (Kijun - 1) * k);
   SetIndexLabel(2, "Senkou Span A");
   SetIndexStyle(0, DRAW_LINE, STYLE_DOT, 1, clrLime);
   SetIndexShift(0, (Kijun - 1) * k);
   SetIndexBuffer(0, SpanA2_Buffer);

   SetIndexStyle(3, DRAW_HISTOGRAM, STYLE_DOT, 1, clrRed);
   SetIndexBuffer(3, SpanB_Buffer);
   SetIndexShift(3, (Kijun - 1) * k);
   SetIndexLabel(3, "Senkou Span B");
   SetIndexStyle(1, DRAW_LINE, STYLE_DOT, 1, clrLime);
   SetIndexBuffer(1, SpanB2_Buffer);
   SetIndexShift(1, (Kijun - 1) * k);

   deleteAllObj();
   if (IsRamp)
   {
      string obj_name;
      for (int i = 0; i < 4; i++)
      {
         if (i == 0)
         {
            obj_name = "5m";
         }
         else if (i == 1)
         {
            obj_name = "15m";
         }
         else if (i == 2)
         {
            obj_name = "30m";
         }
         else if (i == 3)
         {
            obj_name = "60m";
         }
         string obj_name_char = obj_name + "_char";
         // string obj_name_sign = (string)i + "_sign";
         int x_distance = 45 + i * 100;
         int y_distance = 45 + i * 50;
         // ObjectCreate(0, obj_name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
         // ObjectSetInteger(0, obj_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         // ObjectSetInteger(0, obj_name, OBJPROP_XDISTANCE, 30);
         // ObjectSetInteger(0, obj_name, OBJPROP_YDISTANCE, y_distance);
         // ObjectSetInteger(0, obj_name, OBJPROP_XSIZE, 100);
         // ObjectSetInteger(0, obj_name, OBJPROP_YSIZE, 50);
         // ObjectSetInteger(0, obj_name, OBJPROP_BGCOLOR, clrBlue);
         // ObjectSetInteger(0, obj_name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
         // ObjectSetInteger(0, obj_name, OBJPROP_COLOR, clrWhite);
         // ObjectSetInteger(0, obj_name, OBJPROP_STYLE, STYLE_SOLID);
         // ObjectSetInteger(0, obj_name, OBJPROP_WIDTH, 5);

         ObjectCreate(0, obj_name_char, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, obj_name_char, OBJPROP_XDISTANCE, 60);
         ObjectSetInteger(0, obj_name_char, OBJPROP_YDISTANCE, y_distance);
         ObjectSetText(obj_name_char, obj_name, 15, "ＭＳ　ゴシック", White);

         // ObjectCreate(0, obj_name_sign, OBJ_RECTANGLE_LABEL, 0, 0, 0);
         // ObjectSetInteger(0, obj_name_sign, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         // ObjectSetInteger(0, obj_name_sign, OBJPROP_XDISTANCE, 180);
         // ObjectSetInteger(0, obj_name_sign, OBJPROP_YDISTANCE, y_distance);
         // ObjectSetInteger(0, obj_name_sign, OBJPROP_XSIZE, 100);
         // ObjectSetInteger(0, obj_name_sign, OBJPROP_YSIZE, 50);
         // ObjectSetInteger(0, obj_name_sign, OBJPROP_BGCOLOR, clrBlack);
         // ObjectSetInteger(0, obj_name_sign, OBJPROP_BORDER_TYPE, BORDER_FLAT);
         // ObjectSetInteger(0, obj_name_sign, OBJPROP_COLOR, clrWhite);
         // ObjectSetInteger(0, obj_name_sign, OBJPROP_STYLE, STYLE_SOLID);
         // ObjectSetInteger(0, obj_name_sign, OBJPROP_WIDTH, 5);
      }
      calcSenkouSpanForOninit(5, true);
      calcSenkouSpanForOninit(15, true);
      calcSenkouSpanForOninit(30, true);
      calcSenkouSpanForOninit(60, true);
   }

   return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   deleteAllObj();
}
//+------------------------------------------------------------------+
//| Ichimoku Kinko Hyo                                               |
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
   int counted_bar = IndicatorCounted();
   int limit = Bars - IndicatorCounted();
   if (counted_bar == 0)
      limit -= Senkou;
   // 足が更新されたかの判定
   bool isNewCandle = Time[0] != b4Time && limit == 2;
   if (IsRamp)
   {
      calcSenkouSpan(5, isNewCandle);
      calcSenkouSpan(15, isNewCandle);
      calcSenkouSpan(30, isNewCandle);
      calcSenkouSpan(60, isNewCandle);
   }
   if (IsCloud)
   {
      for (int i = limit - 1; i >= 0; i--)
      {
         int shift = iBarShift(NULL, MtfTimeFrameId, time[i], false);

         //---- Tenkan Sen
         double Tenkan_Buffer = (iHigh(NULL, MtfTimeFrameId, iHighest(NULL, MtfTimeFrameId, MODE_HIGH, Tenkan, shift)) + iLow(NULL, MtfTimeFrameId, iLowest(NULL, MtfTimeFrameId, MODE_LOW, Tenkan, shift))) / 2;
         //---- Kijun Sen
         double Kijun_Buffer = (iHigh(NULL, MtfTimeFrameId, iHighest(NULL, MtfTimeFrameId, MODE_HIGH, Kijun, shift)) + iLow(NULL, MtfTimeFrameId, iLowest(NULL, MtfTimeFrameId, MODE_LOW, Kijun, shift))) / 2;
         //---- Senkou Span A
         SpanA_Buffer[i] = (Tenkan_Buffer + Kijun_Buffer) / 2;
         //---- Senkou Span B
         SpanB_Buffer[i] = (iHigh(NULL, MtfTimeFrameId, iHighest(NULL, MtfTimeFrameId, MODE_HIGH, Senkou, shift)) + iLow(NULL, MtfTimeFrameId, iLowest(NULL, MtfTimeFrameId, MODE_LOW, Senkou, shift))) / 2;
         //----kumo
         SpanA2_Buffer[i] = SpanA_Buffer[i];
         SpanB2_Buffer[i] = SpanB_Buffer[i];
      }
   }
   b4Time = Time[0];
   return (rates_total);
}

//+----------------------------------------------------------------------------+
void calcSenkouSpan(int period, bool isNewCandle)
{
   int shift = iBarShift(NULL, period, Time[0], false);
   double Tenkan_Buffer = (iHigh(NULL, period, iHighest(NULL, period, MODE_HIGH, Tenkan, 0)) + iLow(NULL, period, iLowest(NULL, period, MODE_LOW, Tenkan, 0))) / 2;
   //---- Kijun Sen
   double Kijun_Buffer = (iHigh(NULL, period, iHighest(NULL, period, MODE_HIGH, Kijun, 0)) + iLow(NULL, period, iLowest(NULL, period, MODE_LOW, Kijun, 0))) / 2;
   //---- Senkou Span A
   double SpanA_Buffer = (Tenkan_Buffer + Kijun_Buffer) / 2;
   //---- Senkou Span B
   double SpanB_Buffer = (iHigh(NULL, period, iHighest(NULL, period, MODE_HIGH, Senkou, 0)) + iLow(NULL, period, iLowest(NULL, period, MODE_LOW, Senkou, 0))) / 2;
   string obj_name_arrow = (string)period + "m_arrow";
   if (period == 5)
   {
      if (SpanA_Buffer > SpanB_Buffer)
      {
         ObjectDelete(0, obj_name_arrow);
         ObjectCreate(0, obj_name_arrow, OBJ_LABEL, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_XDISTANCE, 150);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_YDISTANCE, 45);
         ObjectSetText(obj_name_arrow, CharToStr(221), 15, "Wingdings", DeepSkyBlue);
         if (isNewCandle && (IsNotification || IsMailNotification))
         {
            if (period5Flag != 1 && Is5mNotification)
            {
               doAlert(5, 1);
               doAlertMail(5, 1);
               period5Flag = 1;
            }
         }
      }
      else if (SpanA_Buffer < SpanB_Buffer)
      {
         ObjectDelete(0, obj_name_arrow);
         ObjectCreate(0, obj_name_arrow, OBJ_LABEL, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_XDISTANCE, 150);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_YDISTANCE, 45);
         ObjectSetText(obj_name_arrow, CharToStr(222), 15, "Wingdings", Red);
         if (isNewCandle && (IsNotification || IsMailNotification))
         {
            if (period5Flag != 2 && Is5mNotification)
            {
               doAlert(5, 2);
               doAlertMail(5, 2);
               period5Flag = 2;
            }
         }
      }
      else
      {
         ObjectDelete(0, obj_name_arrow);
         ObjectCreate(0, obj_name_arrow, OBJ_LABEL, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_XDISTANCE, 150);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_YDISTANCE, 45);
         ObjectSetText(obj_name_arrow, CharToStr(220), 15, "Wingdings", Gray);
         if (isNewCandle && (IsNotification || IsMailNotification))
         {
            if (period5Flag != 3 && Is5mNotification)
            {
               doAlert(5, 3);
               doAlertMail(5, 3);
               period5Flag = 3;
            }
         }
      }
   }
   else if (period == 15)
   {
      if (SpanA_Buffer > SpanB_Buffer)
      {
         ObjectDelete(0, obj_name_arrow);
         ObjectCreate(0, obj_name_arrow, OBJ_LABEL, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_XDISTANCE, 150);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_YDISTANCE, 95);
         ObjectSetText(obj_name_arrow, CharToStr(221), 15, "Wingdings", DeepSkyBlue);
         if (isNewCandle && (IsNotification || IsMailNotification))
         {
            if (period15Flag != 1 && Is15mNotification)
            {
               doAlert(15, 1);
               doAlertMail(15, 1);
               period15Flag = 1;
            }
         }
      }
      else if (SpanA_Buffer < SpanB_Buffer)
      {
         ObjectDelete(0, obj_name_arrow);
         ObjectCreate(0, obj_name_arrow, OBJ_LABEL, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_XDISTANCE, 150);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_YDISTANCE, 95);
         ObjectSetText(obj_name_arrow, CharToStr(222), 15, "Wingdings", Red);

         if (isNewCandle && (IsNotification || IsMailNotification))
         {
            if (period15Flag != 2 && Is15mNotification)
            {
               doAlert(15, 2);
               doAlertMail(15, 2);
               period15Flag = 2;
            }
         }
      }
      else
      {
         ObjectDelete(0, obj_name_arrow);
         ObjectCreate(0, obj_name_arrow, OBJ_LABEL, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_XDISTANCE, 150);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_YDISTANCE, 95);
         ObjectSetText(obj_name_arrow, CharToStr(220), 15, "Wingdings", Gray);
         if (isNewCandle && (IsNotification || IsMailNotification))
         {
            if (period15Flag != 3 && Is15mNotification)
            {
               doAlert(15, 3);
               doAlertMail(15, 3);
               period15Flag = 3;
            }
         }
      }
   }
   else if (period == 30)
   {
      if (SpanA_Buffer > SpanB_Buffer)
      {
         ObjectDelete(0, obj_name_arrow);
         ObjectCreate(0, obj_name_arrow, OBJ_LABEL, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_XDISTANCE, 150);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_YDISTANCE, 145);
         ObjectSetText(obj_name_arrow, CharToStr(221), 15, "Wingdings", DeepSkyBlue);
         if (isNewCandle && (IsNotification || IsMailNotification))
         {
            if (period30Flag != 1 && Is30mNotification)
            {
               doAlert(30, 1);
               doAlertMail(30, 1);
               period30Flag = 1;
            }
         }
      }
      else if (SpanA_Buffer < SpanB_Buffer)
      {
         ObjectDelete(0, obj_name_arrow);
         ObjectCreate(0, obj_name_arrow, OBJ_LABEL, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_XDISTANCE, 150);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_YDISTANCE, 145);
         ObjectSetText(obj_name_arrow, CharToStr(222), 15, "Wingdings", Red);
         if (isNewCandle && (IsNotification || IsMailNotification))
         {
            if (period30Flag != 2 && Is30mNotification)
            {
               doAlert(30, 2);
               doAlertMail(30, 2);
               period30Flag = 2;
            }
         }
      }
      else
      {
         ObjectDelete(0, obj_name_arrow);
         ObjectCreate(0, obj_name_arrow, OBJ_LABEL, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_XDISTANCE, 150);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_YDISTANCE, 145);
         ObjectSetText(obj_name_arrow, CharToStr(220), 15, "Wingdings", Gray);
         if (isNewCandle && (IsNotification || IsMailNotification))
         {
            if (period30Flag != 3 && Is30mNotification)
            {
               doAlert(30, 3);
               doAlertMail(30, 3);
               period30Flag = 3;
            }
         }
      }
   }
   else if (period == 60)
   {
      if (SpanA_Buffer > SpanB_Buffer)
      {
         ObjectDelete(0, obj_name_arrow);
         ObjectCreate(0, obj_name_arrow, OBJ_LABEL, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_XDISTANCE, 150);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_YDISTANCE, 195);
         ObjectSetText(obj_name_arrow, CharToStr(221), 15, "Wingdings", DeepSkyBlue);
         if (isNewCandle && (IsNotification || IsMailNotification))
         {
            if (period60Flag != 1 && Is60mNotification)
            {
               doAlert(60, 1);
               doAlertMail(60, 1);
               period60Flag = 1;
            }
         }
      }
      else if (SpanA_Buffer < SpanB_Buffer)
      {
         ObjectDelete(0, obj_name_arrow);
         ObjectCreate(0, obj_name_arrow, OBJ_LABEL, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_XDISTANCE, 150);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_YDISTANCE, 195);
         ObjectSetText(obj_name_arrow, CharToStr(222), 15, "Wingdings", Red);
         if (isNewCandle && (IsNotification || IsMailNotification))
         {
            if (period60Flag != 2 && Is60mNotification)
            {
               doAlert(60, 2);
               doAlertMail(60, 2);
               period60Flag = 2;
            }
         }
      }
      else
      {
         ObjectDelete(0, obj_name_arrow);
         ObjectCreate(0, obj_name_arrow, OBJ_LABEL, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_XDISTANCE, 150);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_YDISTANCE, 195);
         ObjectSetText(obj_name_arrow, CharToStr(220), 15, "Wingdings", Gray);
         if (isNewCandle && (IsNotification || IsMailNotification))
         {
            if (period60Flag != 3 && Is60mNotification)
            {
               doAlert(60, 3);
               doAlertMail(60, 3);
               period60Flag = 3;
            }
         }
      }
   }
}

//+----------------------------------------------------------------------------+
void calcSenkouSpanForOninit(int period, bool isNewCandle)
{
   int shift = iBarShift(NULL, period, Time[0], false);
   double Tenkan_Buffer = (iHigh(NULL, period, iHighest(NULL, period, MODE_HIGH, Tenkan, 0)) + iLow(NULL, period, iLowest(NULL, period, MODE_LOW, Tenkan, 0))) / 2;
   //---- Kijun Sen
   double Kijun_Buffer = (iHigh(NULL, period, iHighest(NULL, period, MODE_HIGH, Kijun, 0)) + iLow(NULL, period, iLowest(NULL, period, MODE_LOW, Kijun, 0))) / 2;
   //---- Senkou Span A
   double SpanA_Buffer = (Tenkan_Buffer + Kijun_Buffer) / 2;
   //---- Senkou Span B
   double SpanB_Buffer = (iHigh(NULL, period, iHighest(NULL, period, MODE_HIGH, Senkou, 0)) + iLow(NULL, period, iLowest(NULL, period, MODE_LOW, Senkou, 0))) / 2;
   string obj_name_arrow = (string)period + "m_arrow";
   if (period == 5)
   {
      if (SpanA_Buffer > SpanB_Buffer)
      {
         ObjectDelete(0, obj_name_arrow);
         ObjectCreate(0, obj_name_arrow, OBJ_LABEL, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_XDISTANCE, 150);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_YDISTANCE, 45);
         ObjectSetText(obj_name_arrow, CharToStr(221), 15, "Wingdings", DeepSkyBlue);
         if (isNewCandle && (IsNotification || IsMailNotification))
         {
            if (period5Flag != 1 && Is5mNotification)
            {
               period5Flag = 1;
            }
         }
      }
      else if (SpanA_Buffer < SpanB_Buffer)
      {
         ObjectDelete(0, obj_name_arrow);
         ObjectCreate(0, obj_name_arrow, OBJ_LABEL, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_XDISTANCE, 150);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_YDISTANCE, 45);
         ObjectSetText(obj_name_arrow, CharToStr(222), 15, "Wingdings", Red);
         if (isNewCandle && (IsNotification || IsMailNotification))
         {
            if (period5Flag != 2 && Is5mNotification)
            {
               period5Flag = 2;
            }
         }
      }
      else
      {
         ObjectDelete(0, obj_name_arrow);
         ObjectCreate(0, obj_name_arrow, OBJ_LABEL, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_XDISTANCE, 150);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_YDISTANCE, 45);
         ObjectSetText(obj_name_arrow, CharToStr(220), 15, "Wingdings", Gray);
         if (isNewCandle && (IsNotification || IsMailNotification))
         {
            if (period5Flag != 3 && Is5mNotification)
            {
               period5Flag = 3;
            }
         }
      }
   }
   else if (period == 15)
   {
      if (SpanA_Buffer > SpanB_Buffer)
      {
         ObjectDelete(0, obj_name_arrow);
         ObjectCreate(0, obj_name_arrow, OBJ_LABEL, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_XDISTANCE, 150);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_YDISTANCE, 95);
         ObjectSetText(obj_name_arrow, CharToStr(221), 15, "Wingdings", DeepSkyBlue);
         if (isNewCandle && (IsNotification || IsMailNotification))
         {
            if (period15Flag != 1 && Is15mNotification)
            {
               period15Flag = 1;
            }
         }
      }
      else if (SpanA_Buffer < SpanB_Buffer)
      {
         ObjectDelete(0, obj_name_arrow);
         ObjectCreate(0, obj_name_arrow, OBJ_LABEL, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_XDISTANCE, 150);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_YDISTANCE, 95);
         ObjectSetText(obj_name_arrow, CharToStr(222), 15, "Wingdings", Red);

         if (isNewCandle && (IsNotification || IsMailNotification))
         {
            if (period15Flag != 2 && Is15mNotification)
            {
               period15Flag = 2;
            }
         }
      }
      else
      {
         ObjectDelete(0, obj_name_arrow);
         ObjectCreate(0, obj_name_arrow, OBJ_LABEL, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_XDISTANCE, 150);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_YDISTANCE, 95);
         ObjectSetText(obj_name_arrow, CharToStr(220), 15, "Wingdings", Gray);
         if (isNewCandle && (IsNotification || IsMailNotification))
         {
            if (period15Flag != 3 && Is15mNotification)
            {
               period15Flag = 3;
            }
         }
      }
   }
   else if (period == 30)
   {
      if (SpanA_Buffer > SpanB_Buffer)
      {
         ObjectDelete(0, obj_name_arrow);
         ObjectCreate(0, obj_name_arrow, OBJ_LABEL, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_XDISTANCE, 150);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_YDISTANCE, 145);
         ObjectSetText(obj_name_arrow, CharToStr(221), 15, "Wingdings", DeepSkyBlue);
         if (isNewCandle && (IsNotification || IsMailNotification))
         {
            if (period30Flag != 1 && Is30mNotification)
            {
               period30Flag = 1;
            }
         }
      }
      else if (SpanA_Buffer < SpanB_Buffer)
      {
         ObjectDelete(0, obj_name_arrow);
         ObjectCreate(0, obj_name_arrow, OBJ_LABEL, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_XDISTANCE, 150);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_YDISTANCE, 145);
         ObjectSetText(obj_name_arrow, CharToStr(222), 15, "Wingdings", Red);
         if (isNewCandle && (IsNotification || IsMailNotification))
         {
            if (period30Flag != 2 && Is30mNotification)
            {
               period30Flag = 2;
            }
         }
      }
      else
      {
         ObjectDelete(0, obj_name_arrow);
         ObjectCreate(0, obj_name_arrow, OBJ_LABEL, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_XDISTANCE, 150);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_YDISTANCE, 145);
         ObjectSetText(obj_name_arrow, CharToStr(220), 15, "Wingdings", Gray);
         if (isNewCandle && (IsNotification || IsMailNotification))
         {
            if (period30Flag != 3 && Is30mNotification)
            {
               period30Flag = 3;
            }
         }
      }
   }
   else if (period == 60)
   {
      if (SpanA_Buffer > SpanB_Buffer)
      {
         ObjectDelete(0, obj_name_arrow);
         ObjectCreate(0, obj_name_arrow, OBJ_LABEL, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_XDISTANCE, 150);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_YDISTANCE, 195);
         ObjectSetText(obj_name_arrow, CharToStr(221), 15, "Wingdings", DeepSkyBlue);
         if (isNewCandle && (IsNotification || IsMailNotification))
         {
            if (period60Flag != 1 && Is60mNotification)
            {
               period60Flag = 1;
            }
         }
      }
      else if (SpanA_Buffer < SpanB_Buffer)
      {
         ObjectDelete(0, obj_name_arrow);
         ObjectCreate(0, obj_name_arrow, OBJ_LABEL, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_XDISTANCE, 150);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_YDISTANCE, 195);
         ObjectSetText(obj_name_arrow, CharToStr(222), 15, "Wingdings", Red);
         if (isNewCandle && (IsNotification || IsMailNotification))
         {
            if (period60Flag != 2 && Is60mNotification)
            {
               period60Flag = 2;
            }
         }
      }
      else
      {
         ObjectDelete(0, obj_name_arrow);
         ObjectCreate(0, obj_name_arrow, OBJ_LABEL, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_XDISTANCE, 150);
         ObjectSetInteger(0, obj_name_arrow, OBJPROP_YDISTANCE, 195);
         ObjectSetText(obj_name_arrow, CharToStr(220), 15, "Wingdings", Gray);
         if (isNewCandle && (IsNotification || IsMailNotification))
         {
            if (period60Flag != 3 && Is60mNotification)
            {
               period60Flag = 3;
            }
         }
      }
   }
}

void doAlert(int period, int mode)
{
   string status;
   if (mode == 1)
      status = "GC";
   else if (mode == 2)
      status = "DC";
   if (mode == 3)
      status = "Nutral";
   string msg = TimeCurrent() + " " + Symbol() + " " + period + "m " + status;
   Alert(msg);
   SendNotification(msg);
}

void doAlertMail(int period, int mode)
{
   if (IsMailNotification)
   {
      string status;
      if (mode == 1)
         status = "GC";
      else if (mode == 2)
         status = "DC";
      if (mode == 3)
         status = "Nutral";
      string msg = TimeCurrent() + " " + Symbol() + " " + period + "m " + status;
      SendMail(msg, msg);
   }
}

void deleteAllObj()
{
   for (int i = 0; i < ArraySize(ObjArray); i++)
   {
      ObjectDelete(0, ObjArray[i]);
   }
}