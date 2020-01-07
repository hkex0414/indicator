//+------------------------------------------------------------------+
//|                                                  AUTO_CHANEL.mq4 |
//|                                       Copyright 2019, 崩れかけた家 |
//|                            https://discordapp.com/invite/N9PMEym |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, 崩れかけた家"
#property link "https://discordapp.com/invite/N9PMEym"
#property version "1.00"
#property strict
#property indicator_chart_window

//----------------------------------
extern int period = 0;
extern bool ShowFib = true;  // フィボナッチリトレースメント表示切替
extern color FibColor = Red; // フィボナッチリトレースメント表示色
extern int FibSize = 1;      // フィボナッチリトレースメント線の太さ
//------------------
string fib1 = "";
int OnInit()
{
   fib1 = "fib1" + period;
   return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectDelete(fib1);
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
   static datetime curr = 0;
   if (curr != iTime(Symbol(), period, 0))
   {
      curr = iTime(Symbol(), period, 0);
      ObjectDelete(fib1);
      double swing_value[20] = {0, 0, 0, 0};
      datetime swing_date[20] = {0, 0, 0, 0};
      int found = 0;
      double tmp = 0;
      int i = 0;
      while (found < 20)
      {
         if (iCustom(Symbol(), period, "ZigZag", 12, 5, 3, 0, i) != 0)
         {
            swing_value[found] = iCustom(Symbol(), period, "ZigZag", 12, 5, 3, 0, i);
            swing_date[found] = iTime(Symbol(), period, i);
            found++;
         }
         i++;
      }

      ObjectDelete(fib1);
      if (ShowFib)
      {
         ObjectCreate(fib1, OBJ_FIBO, 0, swing_date[2], swing_value[2], swing_date[1], swing_value[1]);
         ObjectSet(fib1, OBJPROP_FIBOLEVELS, 10);
         ObjectSet(fib1, OBJPROP_FIRSTLEVEL, 0.0);
         ObjectSetFiboDescription(fib1, 0, "0    %$");
         ObjectSet(fib1, OBJPROP_FIRSTLEVEL + 1, 0.236);
         ObjectSetFiboDescription(fib1, 1, "23.6     %$");
         ObjectSet(fib1, OBJPROP_FIRSTLEVEL + 2, 0.382);
         ObjectSetFiboDescription(fib1, 2, "38.2     %$");
         ObjectSet(fib1, OBJPROP_FIRSTLEVEL + 3, 0.50);
         ObjectSetFiboDescription(fib1, 3, "50.0     %$");
         ObjectSet(fib1, OBJPROP_FIRSTLEVEL + 4, 0.618);
         ObjectSetFiboDescription(fib1, 4, "61.8     %$");
         ObjectSet(fib1, OBJPROP_FIRSTLEVEL + 5, 0.786);
         ObjectSetFiboDescription(fib1, 5, "78.6     %$");
         ObjectSet(fib1, OBJPROP_FIRSTLEVEL + 6, 1.000);
         ObjectSetFiboDescription(fib1, 6, "100    %$");
         ObjectSet(fib1, OBJPROP_FIRSTLEVEL + 7, 1.618);
         ObjectSetFiboDescription(fib1, 7, "161.8     %$");
         ObjectSet(fib1, OBJPROP_FIRSTLEVEL + 8, 2.618);
         ObjectSetFiboDescription(fib1, 8, "261.8     %$");
         ObjectSet(fib1, OBJPROP_FIRSTLEVEL + 9, 4.236);
         ObjectSetFiboDescription(fib1, 9, "423.6     %$");
         ObjectSet(fib1, OBJPROP_LEVELCOLOR, FibColor);
         ObjectSet(fib1, OBJPROP_LEVELWIDTH, FibSize);
      }
   }

   return (0);
}