#ifndef LAMP_SIMULATOR_H
#define LAMP_SIMULATOR_H

#include "llvm/Pass.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallSet.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/IR/CallSite.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ValueMap.h"

#define DEBUG_TYPE "lamp-simulator"

llvm::cl::opt<int> SimMantissaSize("mantissa", llvm::cl::value_desc("bits"),
    llvm::cl::desc("Size of the mantissa in bits"), llvm::cl::init(8));
    
llvm::cl::opt<int> SimCvtMantissaSize("cvt-mant", llvm::cl::value_desc("bits"),
  llvm::cl::desc("Size of the FCvt unit mantissa in bits"), llvm::cl::init(0));
llvm::cl::opt<int> SimAddMantissaSize("add-mant", llvm::cl::value_desc("bits"),
  llvm::cl::desc("Size of the FAdd mantissa in bits"), llvm::cl::init(0));
llvm::cl::opt<int> SimSubMantissaSize("sub-mant", llvm::cl::value_desc("bits"),
  llvm::cl::desc("Size of the FSub mantissa in bits"), llvm::cl::init(0));
llvm::cl::opt<int> SimMulMantissaSize("mul-mant", llvm::cl::value_desc("bits"),
  llvm::cl::desc("Size of the FMul mantissa in bits"), llvm::cl::init(0));
llvm::cl::opt<int> SimDivMantissaSize("div-mant", llvm::cl::value_desc("bits"),
  llvm::cl::desc("Size of the FDiv mantissa in bits"), llvm::cl::init(0));

namespace lamp {

class LAMPSimulator : public llvm::FunctionPass {
  int simulatedMantissaSize(llvm::Instruction& I);
  void visit(llvm::Instruction& I);
  
public:
  static char ID;
  
  LAMPSimulator() : FunctionPass(ID) {};
  
  bool runOnFunction(llvm::Function &F) override;
};

} // namespace lamp

#endif
