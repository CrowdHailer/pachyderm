defmodule Pachyderm.Adjustment do
  defstruct [
    entity: nil,
    attribute: nil,
    value: nil,
    transaction: nil,
    set: nil
  ]

  def set(entity, attribute, value) do
    %__MODULE__{
      entity: entity, attribute: attribute, value: value, set: true
    }
  end
  def set_state(entity, state) do
    %__MODULE__{
      entity: entity, attribute: :__struct__, value: state, set: true
    }
  end
  def unset(entity, attribute, value) do
    %__MODULE__{
      entity: entity, attribute: attribute, value: value, set: false
    }
  end
  def unset_state(entity, state) do
    %__MODULE__{
      entity: entity, attribute: :__struct__, value: state, set: false
    }
  end
end
