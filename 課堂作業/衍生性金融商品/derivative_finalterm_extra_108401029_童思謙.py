import numpy as np

class option:
    def __init__(self,AorE,option_type,S0,K,T,point,r,sigma,simulation) :
        self.AorE = str(AorE)
        self.option_type = str(option_type)
        self.S0 = float(S0)
        self.K = float(K)
        self.r = float(r)
        self.sigma = float(sigma)
        self.T = float(T)
        self.point = int(point)
        self.simulation = int(simulation)
        
        self.dt = self.T/self.point
        self.discount = np.exp(-self.r*self.dt)
    @property    
    def price_path(self,seed = 123 ) :
        np.random.seed(seed) 
        price_path = np.zeros((self.point+1,self.simulation),dtype = np.float64)
        price_path[0,:] = self.S0
        
        for t in range(1,self.point +1) :
            brownian = np.random.standard_normal( int(self.simulation / 2))
            brownian = np.concatenate((brownian, -brownian))
            price_path[t,:] = (price_path[t-1,:]*np.exp((self.r-(self.sigma**2)/2)*self.dt + self.sigma*np.sqrt(self.dt)*brownian))
        return price_path
    @property 
    def payoff(self):
        if self.option_type  =='put':
            payoff  = np.maximum((self.K - self.price_path) ,np.zeros((self.point+1,self.simulation),dtype = np.float64))
        else :
            payoff = np.maximum((self.price_path - self.K),np.zeros((self.point+1,self.simulation),dtype = np.float64))
        return payoff
    @property 
    def cashflow(self) :
        cashflow = np.zeros_like(self.payoff)
        cashflow[-1,:] = self.payoff[-1,:]
        for i in range(self.point-1,0,-1) :
            regression = np.polyfit(self.price_path[i,:] ,cashflow[i+1,:]*np.exp(-self.r*self.dt),5) 
            future_discount_payoff  = np.polyval(regression,self.price_path[i,:])
            cashflow[i,:] = np.where(future_discount_payoff<self.payoff[i,:],self.payoff[i,:],cashflow[i+1,:]*np.exp(-self.r*self.dt))
        return cashflow[1,:]*self.discount
         #future payoff 最小值為0 self payoff最小值也為0，future_payoff<self.payoff[i,:]就隱含self.payoff[i,:]必為履約價值大於0的路徑
    @property        
    def option_price(self):
        
        if self.AorE =='A':
            return np.sum(self.cashflow)/float(self.simulation)
        else : 
            return np.sum(self.payoff[self.point,:]*np.exp(-self.r*self.T))/float(self.simulation)   
    
    
        
        
    
#AorE的欄位可以輸入A(美式) 或 E(歐式),option_type的欄位可以輸入put 或 call ex. option('AorE', 'option_type', S0, strike, T, M, r, sigma, simulations)   

AmericanPUT = option('A','put', 36, 40., 1., 50, 0.06, 0.2, 10000 )
print('AmericanPUT Price: ', AmericanPUT.option_price)

EuropeanPUT = option('E','put', 36, 40., 1., 50, 0.06, 0.2, 10000 )
print('EuropeanPUT Price: ', EuropeanPUT.option_price)

AmericanCall = option('A','call', 36, 40., 1, 50, 0.06, 0.2, 10000 )
print('AmericanCall Price: ', AmericanCall.option_price)

EuropeanCall = option('E','call', 36, 40., 1, 50, 0.06, 0.2, 10000 )
print('EuropeanCall Price: ', EuropeanCall.option_price)
#@property讓method被調用時不必加上()，EX.option_price() -> option_price  
