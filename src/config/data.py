from enum import Enum

from dataclasses import dataclass, field
from hydra.core.config_store import ConfigStore
from typing import Tuple, Any
from omegaconf import MISSING

class DataFormatKind(Enum):
    channels_last  = 0
    channels_first = 1

class RandomMode(Enum):
    random_blocks = 0
    serial_access = 1

@dataclass
class DatasetPaths:
    train: str  = "/data/datasets/SBND/cosmic_tagging_2/cosmic_tagging_2_val.h5"
    test:  str  = "/data/datasets/SBND/cosmic_tagging_2/cosmic_tagging_2_test.h5"
    val:   str  = "/data/datasets/SBND/cosmic_tagging_2/cosmic_tagging_2_val.h5"
    active: Tuple[str] =  field(default_factory=list) 


@dataclass
class Data:
    synthetic:              bool = False
    downsample:              int = 1
    data_format: DataFormatKind  = DataFormatKind.channels_last
    version:                 int = 2 # Pick 1 or 2
    
@dataclass
class Real(Data):
    random_mode:      RandomMode = RandomMode.random_blocks
    img_transform:          bool = False
    seed:                    int = -1 # Random number seed
    paths:          DatasetPaths = DatasetPaths()

# @dataclass
# class Train(Data):
#     synthetic:      bool = False
#     path:           str  = "/data/datasets/SBND/cosmic_tagging_2/cosmic_tagging_2_train.h5"

# @dataclass
# class Test(Data):
#     synthetic:      bool = False
#     path:           str  = "/data/datasets/SBND/cosmic_tagging_2/cosmic_tagging_2_test.h5"
#     seed:           int  = 0

# @dataclass
# class Val(Data):
#     synthetic:      bool = False
#     path:           str  = "/data/datasets/SBND/cosmic_tagging_2/cosmic_tagging_2_val.h5"


@dataclass
class Synthetic(Data):
    synthetic: bool = True


cs = ConfigStore.instance()
cs.store(group="data", name="real", node=Real)
# cs.store(group="data", name="val", node=Val)
# cs.store(group="data", name="test", node=Test)
cs.store(group="data", name="synthetic", node=Synthetic)
