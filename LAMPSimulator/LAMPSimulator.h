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

llvm::cl::opt<int> SimMantissaSize("mantSize", llvm::cl::value_desc("bits"),
    llvm::cl::desc("Size of the mantissa in bits"), llvm::cl::init(8));

namespace lamp {

class LAMPSimulator : public llvm::FunctionPass {
  void visit(llvm::Instruction& I);
  
public:
  static char ID;
  
  LAMPSimulator() : FunctionPass(ID) {};
  
  bool runOnFunction(llvm::Function &F) override;
};

} // namespace lamp

#endif
