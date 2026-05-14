  } catch (error) {
    console.error('❌ Failed to connect to database:', error);
    // For development without MySQL, return a mock database
    if (process.env.NODE_ENV !== 'production') {
      console.log('⚠️ Using mock database for development');
      return {
        query: async () => [],
        select: () => ({
          from: () => ({
            where: () => ({ 
              limit: () => Promise.resolve([]),
              execute: () => Promise.resolve([])
            }),
            limit: () => Promise.resolve([]),
            execute: () => Promise.resolve([])
          })
        }),
        insert: () => ({ 
          values: () => ({ 
            execute: async () => ({ insertId: 0 }) 
          }) 
        }),
        update: () => ({ 
          set: () => ({ 
            where: () => Promise.resolve({ changes: 0 }) 
          }) 
        }),
        delete: () => ({ 
          from: () => ({ 
            where: () => Promise.resolve({ changes: 0 }) 
          }) 
        }),
      } as any;
    }
    return null;
  }
