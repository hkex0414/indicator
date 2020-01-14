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
#property indicator_buffers 2
#property indicator_color1 LawnGreen
#property indicator_color2 Red

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
extern bool SoundON = false;
extern bool EmailON = false;

extern int FastMA_Mode = 0; //0=sma, 1=ema, 2=smma, 3=lwma, 4=lsma
extern int FastMA_Period = 1;
extern int FastMA_Shift = 0;
extern int FastPriceMode = 0; //0=close, 1=open, 2=high, 3=low, 4=median(high+low)/2, 5=typical(high+low+close)/3, 6=weighted(high+low+close+close)/4
extern int SlowMA_Mode = 0;   //0=sma, 1=ema, 2=smma, 3=lwma, 4=lsma
extern int SlowMA_Period = 1;
extern int SlowMA_Shift = -26;
extern int SlowPriceMode = 0; //0=close, 1=open, 2=high, 3=low, 4=median(high+low)/2, 5=typical(high+low+close)/3, 6=weighted(high+low+close+close)/4
//---------------------------

//-------変数・定数定義-------
// Camel方式
// アラート重複排除用
datetime b4Time;
int flagval1 = 0;
int flagval2 = 0;
//---------------------------

//----------配列定義---------
// Camel方式
double CrossUp[];
double CrossDown[];
//---------------------------

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexStyle(0, DRAW_ARROW, EMPTY, 3);
   SetIndexArrow(0, 233);
   SetIndexBuffer(0, CrossUp);
   SetIndexStyle(1, DRAW_ARROW, EMPTY, 3);
   SetIndexArrow(1, 234);
   SetIndexBuffer(1, CrossDown);
   GlobalVariableSet("AlertTime" + Symbol() + Period(), CurTime());
   GlobalVariableSet("SignalType" + Symbol() + Period(), OP_SELLSTOP);

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
   int limit, i, counter;
   double tmp = 0;
   double fastMAnow, slowMAnow, fastMAprevious, slowMAprevious;
   double Range, AvgRange;
   int counted_bars = IndicatorCounted();
   //---- check for possible errors
   if (counted_bars < 0)
      return (-1);
   //---- last counted bar will be recounted
   if (counted_bars > 0)
      counted_bars--;

   limit = Bars - counted_bars;
   for (i = 0; i <= limit; i++)
   {

      counter = i;
      Range = 0;
      AvgRange = 0;
      for (counter = i; counter <= i + 9; counter++)
      {
         AvgRange = AvgRange + MathAbs(High[counter] - Low[counter]);
      }
      Range = AvgRange / 10;

      if (FastMA_Mode == 4)
      {
         fastMAnow = LSMA(FastMA_Period, FastPriceMode, i);
         fastMAprevious = LSMA(FastMA_Period, FastPriceMode, i + 1);
      }
      else
      {
         fastMAnow = iMA(NULL, 0, FastMA_Period, FastMA_Shift, FastMA_Mode, FastPriceMode, i);
         fastMAprevious = iMA(NULL, 0, FastMA_Period, FastMA_Shift, FastMA_Mode, FastPriceMode, i + 1);
      }

      if (SlowMA_Mode == 4)
      {
         slowMAnow = LSMA(SlowMA_Period, SlowPriceMode, i);
         slowMAprevious = LSMA(SlowMA_Period, SlowPriceMode, i + 1);
      }
      else
      {
         slowMAnow = iMA(NULL, 0, SlowMA_Period, SlowMA_Shift, SlowMA_Mode, SlowPriceMode, i);
         slowMAprevious = iMA(NULL, 0, SlowMA_Period, SlowMA_Shift, SlowMA_Mode, SlowPriceMode, i + 1);
      }

      if ((fastMAnow > slowMAnow) && (fastMAprevious < slowMAprevious))
      {
         if (i == 1 && flagval1 == 0)
         {
            flagval1 = 1;
            flagval2 = 0;
         }
         CrossUp[i] = Low[i] - Range * 0.75;
      }
      else if ((fastMAnow < slowMAnow) && (fastMAprevious > slowMAprevious))
      {
         if (i == 1 && flagval2 == 0)
         {
            flagval2 = 1;
            flagval1 = 0;
         }
         CrossDown[i] = High[i] + Range * 0.75;
      }
   }

   if (flagval1 == 1 && CurTime() > GlobalVariableGet("AlertTime" + Symbol() + Period()) && GlobalVariableGet("SignalType" + Symbol() + Period()) != OP_BUY)
   {
      //      if (GlobalVariableGet("LastAlert"+Symbol()+Period()) < 0.5)
      //      {
      if (SoundON)
         Alert("BUY signal at Ask=", Ask, "\n Bid=", Bid, "\n Time=", TimeToStr(CurTime(), TIME_DATE), " ", TimeHour(CurTime()), ":", TimeMinute(CurTime()), "\n Symbol=", Symbol(), " Period=", Period());
      if (EmailON)
         SendMail("BUY signal alert", "BUY signal at Ask=" + DoubleToStr(Ask, 4) + ", Bid=" + DoubleToStr(Bid, 4) + ", Date=" + TimeToStr(CurTime(), TIME_DATE) + " " + TimeHour(CurTime()) + ":" + TimeMinute(CurTime()) + " Symbol=" + Symbol() + " Period=" + Period());
      //      }
      tmp = CurTime() + (Period() - MathMod(Minute(), Period())) * 60;
      GlobalVariableSet("AlertTime" + Symbol() + Period(), tmp);
      GlobalVariableSet("SignalType" + Symbol() + Period(), OP_SELL);
      //      GlobalVariableSet("LastAlert"+Symbol()+Period(),1);
   }

   if (flagval2 == 1 && CurTime() > GlobalVariableGet("AlertTime" + Symbol() + Period()) && GlobalVariableGet("SignalType" + Symbol() + Period()) != OP_SELL)
   {
      //      if (GlobalVariableGet("LastAlert"+Symbol()+Period()) > -0.5)
      //      {
      if (SoundON)
         Alert("SELL signal at Ask=", Ask, "\n Bid=", Bid, "\n Date=", TimeToStr(CurTime(), TIME_DATE), " ", TimeHour(CurTime()), ":", TimeMinute(CurTime()), "\n Symbol=", Symbol(), " Period=", Period());
      if (EmailON)
         SendMail("SELL signal alert", "SELL signal at Ask=" + DoubleToStr(Ask, 4) + ", Bid=" + DoubleToStr(Bid, 4) + ", Date=" + TimeToStr(CurTime(), TIME_DATE) + " " + TimeHour(CurTime()) + ":" + TimeMinute(CurTime()) + " Symbol=" + Symbol() + " Period=" + Period());
      //      }
      tmp = CurTime() + (Period() - MathMod(Minute(), Period())) * 60;
      GlobalVariableSet("AlertTime" + Symbol() + Period(), tmp);
      GlobalVariableSet("SignalType" + Symbol() + Period(), OP_BUY);
      //      GlobalVariableSet("LastAlert"+Symbol()+Period(),-1);
   }
   return (rates_total);
}

double LSMA(int Rperiod, int prMode, int shift)
{
   int i;
   double sum, pr;
   int length;
   double lengthvar;
   double tmp;
   double wt;

   length = Rperiod;

   sum = 0;
   for (i = length; i >= 1; i--)
   {
      lengthvar = length + 1;
      lengthvar /= 3;
      tmp = 0;
      switch (prMode)
      {
      case 0:
         pr = Close[length - i + shift];
         break;
      case 1:
         pr = Open[length - i + shift];
         break;
      case 2:
         pr = High[length - i + shift];
         break;
      case 3:
         pr = Low[length - i + shift];
         break;
      case 4:
         pr = (High[length - i + shift] + Low[length - i + shift]) / 2;
         break;
      case 5:
         pr = (High[length - i + shift] + Low[length - i + shift] + Close[length - i + shift]) / 3;
         break;
      case 6:
         pr = (High[length - i + shift] + Low[length - i + shift] + Close[length - i + shift] + Close[length - i + shift]) / 4;
         break;
      }
      tmp = (i - lengthvar) * pr;
      sum += tmp;
   }
   wt = sum * 6 / (length * (length + 1));

   return (wt);
}
