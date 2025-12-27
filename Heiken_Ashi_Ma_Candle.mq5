//+------------------------------------------------------------------+
//|                                        Heiken_Ashi_Ma_Candle.mq5 |
//|                             Copyright 2000-2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2000-2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 9
#property indicator_plots   1

#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  clrDeepSkyBlue,clrPaleVioletRed
#property indicator_label1  "Heiken Ashi Open;Heiken Ashi High;Heiken Ashi Low;Heiken Ashi Close"

#define MA_PERIOD 21

//--- indicator buffers
double ExtOpenBuffer[], ExtHighBuffer[], ExtLowBuffer[], ExtCloseBuffer[];
double ExtColorBuffer[];
double MaOpenBuffer[], MaHighBuffer[], MaLowBuffer[], MaCloseBuffer[];

//--- indicator handles
int hMaOpen;
int hMaHigh;
int hMaLow;
int hMaClose;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- indicator buffers mapping
   SetIndexBuffer(0,ExtOpenBuffer, INDICATOR_DATA);
   SetIndexBuffer(1,ExtHighBuffer, INDICATOR_DATA);
   SetIndexBuffer(2,ExtLowBuffer,  INDICATOR_DATA);
   SetIndexBuffer(3,ExtCloseBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,ExtColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(5,MaOpenBuffer,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,MaHighBuffer,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,MaLowBuffer,   INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,MaCloseBuffer, INDICATOR_CALCULATIONS);
   //---
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   //--- sets first bar from what index will be drawn
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,MA_PERIOD-1);
   IndicatorSetString(INDICATOR_SHORTNAME,"Heiken Ashi Ma Candle");
   //--- sets drawing line empty value
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);

   //--- get MA handles
   hMaOpen  = iMA(NULL,0,MA_PERIOD,0,MODE_EMA,PRICE_OPEN);
   hMaHigh  = iMA(NULL,0,MA_PERIOD,0,MODE_EMA,PRICE_HIGH);
   hMaLow   = iMA(NULL,0,MA_PERIOD,0,MODE_EMA,PRICE_LOW);
   hMaClose = iMA(NULL,0,MA_PERIOD,0,MODE_EMA,PRICE_CLOSE);
   
   if(
      (hMaOpen  == INVALID_HANDLE) ||
      (hMaHigh  == INVALID_HANDLE) ||
      (hMaLow   == INVALID_HANDLE) ||
      (hMaClose == INVALID_HANDLE)
   )
   {
      Print("Error: INVALID_HANDLE");
      return(INIT_FAILED);
   }
   
   //---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Heiken Ashi                                                      |
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
   //---
   if(
      (BarsCalculated(hMaOpen)  < rates_total) ||
      (BarsCalculated(hMaHigh)  < rates_total) ||
      (BarsCalculated(hMaLow)   < rates_total) ||
      (BarsCalculated(hMaClose) < rates_total)
   )
      return(0);
      
   int to_copy;
   to_copy = rates_total - prev_calculated;
   if(to_copy==0)
      to_copy++;

   if( CopyBuffer(hMaOpen,0,0,to_copy,MaOpenBuffer) <= 0 ) return(0);
   if( CopyBuffer(hMaHigh,0,0,to_copy,MaHighBuffer) <= 0 ) return(0);
   if( CopyBuffer(hMaLow,0,0,to_copy,MaLowBuffer) <= 0 ) return(0);
   if( CopyBuffer(hMaClose,0,0,to_copy,MaCloseBuffer) <= 0 ) return(0);
   
   //--- preliminary calculations
   int start;
   if(prev_calculated==0)
   {
      ExtLowBuffer[0]=low[0];
      ExtHighBuffer[0]=high[0];
      ExtOpenBuffer[0]=open[0];
      ExtCloseBuffer[0]=close[0];
      start=1;
   }
   else
      start=prev_calculated-1;

   //--- the main loop of calculations
   for(int i=start; i<rates_total && !IsStopped(); i++)
   {
      double ha_open =(ExtOpenBuffer[i-1]+ExtCloseBuffer[i-1])/2;
      double ha_close=(MaOpenBuffer[i]+MaHighBuffer[i]+MaLowBuffer[i]+MaCloseBuffer[i])/4;
      double ha_high = MathMax(ha_open,ha_close);  //--- MathMax(high[i],MathMax(ha_open,ha_close));
      double ha_low  = MathMin(ha_open,ha_close);  //--- MathMin(low[i], MathMin(ha_open,ha_close));

      ExtLowBuffer[i]=ha_low;
      ExtHighBuffer[i]=ha_high;
      ExtOpenBuffer[i]=ha_open;
      ExtCloseBuffer[i]=ha_close;

      //--- set candle color
      if(ha_open < ha_close)
         ExtColorBuffer[i]=0.0; // set color DodgerBlue
      else
         ExtColorBuffer[i]=1.0; // set color Red
   }

   //---
   return(rates_total);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(hMaOpen);
   IndicatorRelease(hMaClose);
   IndicatorRelease(hMaLow);
   IndicatorRelease(hMaHigh);
}
//+------------------------------------------------------------------+
