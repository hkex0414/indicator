//+------------------------------------------------------------------+
//|                                                     TEMPLETE.mq4 |
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
//---------------------------

#property indicator_buffers 6
#property indicator_color1 Blue
#property indicator_color2 Blue
#property indicator_color3 Blue
#property indicator_color4 Blue
#property indicator_color5 Blue
#property indicator_color6 Blue

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
TimeFrameList MtfTimeFrame = Current_timeFrame; // MTFで表示させる時間軸
// EMAの期間を定義（外部パラメータ）
extern int EMA1 = 3;
extern int EMA2 = 5;
extern int EMA3 = 8;
extern int EMA4 = 10;
extern int EMA5 = 12;
extern int EMA6 = 15;
//---------------------------

//-------変数・定数定義-------
// Camel方式
// アラート重複排除用
datetime b4Time;
//---------------------------

//----------配列定義---------
// Camel方式
double buf0[];
double buf1[];
double buf2[];
double buf3[];
double buf4[];
double buf5[];

//---------------------------

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   // 指標バッファを割り当てる
   SetIndexBuffer(0, buf0);
   SetIndexBuffer(1, buf1);
   SetIndexBuffer(2, buf2);
   SetIndexBuffer(3, buf3);
   SetIndexBuffer(4, buf4);
   SetIndexBuffer(5, buf5);

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
   int countedBar = IndicatorCounted();
   int limit = Bars - countedBar;

   // EMAを6本チャートへ表示
   for (int i = limit - 1; i >= 0; i--)
   {
      buf0[i] = iMA(NULL, 0, EMA1, 0, MODE_EMA, PRICE_CLOSE, i);
      buf1[i] = iMA(NULL, 0, EMA2, 0, MODE_EMA, PRICE_CLOSE, i);
      buf2[i] = iMA(NULL, 0, EMA3, 0, MODE_EMA, PRICE_CLOSE, i);
      buf3[i] = iMA(NULL, 0, EMA4, 0, MODE_EMA, PRICE_CLOSE, i);
      buf4[i] = iMA(NULL, 0, EMA5, 0, MODE_EMA, PRICE_CLOSE, i);
      buf5[i] = iMA(NULL, 0, EMA6, 0, MODE_EMA, PRICE_CLOSE, i);
   }
   //--- return value of prev_calculated for next call
   return (rates_total);
}
