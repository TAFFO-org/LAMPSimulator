#include "LAMPSimulator.h"


using namespace llvm;
using namespace lamp;


char LAMPSimulator::ID = 0;

static RegisterPass<LAMPSimulator> X(
        "lampsim",
        "LAMP mantissa simulation pass",
        true /* Does not only look at CFG */,
        true /* Optimization Pass */);
        

bool LAMPSimulator::runOnFunction(Function &F) {
  for (BasicBlock& BB: F) {
    auto II = BB.begin();
    while (II != BB.end()) {
      Instruction& I = *II++;
      
      if (I.getOpcode() == Instruction::FAdd ||
          I.getOpcode() == Instruction::FSub ||
          I.getOpcode() == Instruction::FMul ||
          I.getOpcode() == Instruction::FDiv ||
          isa<FPExtInst>(I) || isa<FPTruncInst>(I) ||
          isa<SIToFPInst>(I) || isa<UIToFPInst>(I))
        visit(I);
    }
  }
  return true;
}


void LAMPSimulator::visit(Instruction& I) {
  Instruction *IClone = I.clone();
  IClone->insertAfter(&I);
  IClone->setName(I.getName());
  
  Type *OrigFloatType = I.getType();
  assert(OrigFloatType->isFloatingPointTy() && "type of instruction not float");
  
  uint64_t SizeOfFloat = OrigFloatType->getPrimitiveSizeInBits().getFixedSize();
  uint64_t OldMantissaSize = OrigFloatType->getFPMantissaWidth();
  assert(OldMantissaSize > 0 && "strange float types not supported");
  int64_t Mask = (int64_t)(-1) << (OldMantissaSize - SimMantissaSize);
  
  Type *TempIntType = Type::getIntNTy(
      I.getContext(), OrigFloatType->getPrimitiveSizeInBits());
  
  IRBuilder<> Builder(IClone->getNextNonDebugInstruction());
  Value *SimFloat = Builder.CreateBitCast(
    Builder.CreateAnd(
      Builder.CreateBitCast(IClone, TempIntType, "lampsim"),
      Mask, "lampsim"),
    OrigFloatType, "lampsim");
  
  I.replaceAllUsesWith(SimFloat);
  I.removeFromParent();
  I.deleteValue();
}


