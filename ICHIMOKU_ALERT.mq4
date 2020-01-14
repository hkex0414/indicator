//+------------------------------------------------------------------+
//|                                               ICHIMOKU_ALERT.mq4 |
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
#property indicator_buffers 5
#property indicator_color1 clrYellow
#property indicator_color2 clrRed
#property indicator_color3 clrGreen
#property indicator_color4 clrBlue
#property indicator_color5 clrPink
#property indicator_width4 2
#property indicator_width5 2

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
// int MtfTimeFrameId;
// extern TimeFrameList MtfTimeFrameId = Current_timeFrame; // MTFで表示させる時間軸
extern int ma3_shift = -26;    //遅行スパン（表示移動）
extern bool boolAlart = false; //アラート
//---------------------------

//-------変数・定数定義-------
// Camel方式
// アラート重複排除用
datetime b4Time;
int counts = 0;
//---------------------------

//----------配列定義---------
// Camel方式
double MovingBuffer1[];
double MovingBuffer2[];
double MovingBuffer3[];
double upSign[];
double downSign[];
//---------------------------

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0, MovingBuffer1);
   SetIndexBuffer(1, MovingBuffer2);
   SetIndexBuffer(2, MovingBuffer3);
   SetIndexBuffer(3, upSign);
   SetIndexBuffer(4, downSign);

   SetIndexStyle(0, DRAW_LINE);
   SetIndexStyle(1, DRAW_LINE);
   SetIndexStyle(2, DRAW_LINE);
   SetIndexStyle(3, DRAW_ARROW);
   SetIndexStyle(4, DRAW_ARROW);

   SetIndexArrow(3, SYMBOL_ARROWUP);
   SetIndexArrow(4, SYMBOL_ARROWDOWN);

   SetIndexShift(2, ma3_shift);

   return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   GlobalVariableDel("AlertTime" + Symbol() + Period());
   GlobalVariableDel("SignalType" + Symbol() + Period());
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
   int limit = rates_total - prev_calculated;

   if (limit > 0)
   {
      limit = rates_total - MathMax(ma2_period, MathAbs(ma3_shift)) - 2;
      counts = 0;
   }

   for (int i = limit; i >= 0; i--)
   {

      MovingBuffer1[i] = EMPTY_VALUE;
      MovingBuffer2[i] = EMPTY_VALUE;
      MovingBuffer3[i] = EMPTY_VALUE;
      upSign[i] = EMPTY_VALUE;
      downSign[i] = EMPTY_VALUE;

      MovingBuffer1[i] = iMA(NULL, 0, 1, 0, MODE_SMA, PRICE_CLOSE, i);
      MovingBuffer2[i] = iMA(NULL, 0, 1, 0, MODE_SMA, PRICE_CLOSE, i);

      MovingBuffer3[i] = iMA(NULL, 0, 1, 0, MODE_SMA, PRICE_CLOSE, i);

      if (MovingBuffer3[i + 1] < MovingBuffer2[i - ma3_shift + 1] && MovingBuffer2[i - ma3_shift] <= MovingBuffer3[i])
      {

         upSign[i] = close[i];
      }
      if (MovingBuffer3[i + 1] > MovingBuffer2[i - ma3_shift + 1] && MovingBuffer2[i - ma3_shift] >= MovingBuffer3[i])
      {

         downSign[i] = close[i];
      }
   }

   if (counts == 0 && boolAlart)
   {

      if (upSign[1] != EMPTY_VALUE)
      {
         Alert(Symbol() + " [UP] ");
         counts++;
      }

      if (downSign[1] != EMPTY_VALUE)
      {
         Alert(Symbol() + " [DOWN]");
         counts++;
      }
   }

   return (rates_total);
}