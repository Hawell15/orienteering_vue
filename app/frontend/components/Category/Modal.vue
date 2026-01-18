<template>
    <div class="modal fade" tabindex="-1" id="editModal" aria-labelledby="editModalLabel" aria-hidden="true" ref="modalRef">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="editModalLabel">{{ isNew ? 'Creaza Categorie' : 'Editeaza Categoria'}}</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <form @submit.prevent>
                        <div class="mb-3">
                            <label for="category_name" class="form-label">Nume</label>
                            <input type="text" class="form-control" id="category_name" v-model="localCategory.category_name" />
                        </div>
                        <div class="mb-3">
                            <label for="full_name" class="form-label">Nume Complet</label>
                            <input type="text" class="form-control" id="full_name" v-model="localCategory.full_name" />
                        </div>
                        <div class="mb-3">
                            <label for="points" class="form-label">Puncte</label>
                            <input type="number" class="form-control" id="points" v-model="localCategory.points" />
                        </div>
                        <div class="mb-3">
                            <label for="validaty_period" class="form-label">Valabilitate(ani)</label>
                            <input type="number" class="form-control" id="validaty_period" v-model="localCategory.validaty_period" />
                        </div>
                    </form>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Inchide</button>
                    <button type="button" class="btn btn-primary" @click="handleSave">Salveaza</button>
                </div>
            </div>
        </div>
    </div>
</template>
<script setup>
import { ref, watch, onMounted } from 'vue'
const props = defineProps({
    category: Object,
    isNew: Boolean
})

const emit = defineEmits(['save'])
const localCategory = ref({ ...props.category })
const modalRef = ref(null)
let modalInstance = null

watch(
    () => props.category,
    (newVal) => {
        localCategory.value = { ...newVal }
    }
)

function show() {
    if (!modalInstance) {
        modalInstance = new bootstrap.Modal(modalRef.value)
    }
    modalInstance.show()
}

function hide() {
    modalInstance?.hide()
}

function handleSave() {
    emit('save', localCategory.value, hide)
}

defineExpose({ show, hide })
</script>
