<template>
    <div class="modal fade" tabindex="-1" aria-hidden="true" ref="modalRef">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Unește sportivi</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <table class="table table-bordered table-striped">
                        <thead class="table-primary">
                            <tr>
                                <th>Atribut</th>
                                <th>Principal</th>
                                <th>Adăugat</th>
                                <th>Altă</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="attr in attributes" :key="attr.key">
                                <td>{{ attr.label }}</td>
                                <td class="selectable" :class="{ selected: selections[attr.key] === 'main' }" @click="selectSource(attr.key, 'main')">
                                    {{ attr.display ? attr.display(mainRunner) : mainRunner?.[attr.key] }}
                                </td>
                                <td class="selectable" :class="{ selected: selections[attr.key] === 'merged' }" @click="selectSource(attr.key, 'merged')">
                                    {{ attr.display ? attr.display(mergedRunner) : mergedRunner?.[attr.key] }}
                                </td>
                                <td :class="{ selected: selections[attr.key] === 'other' }">
                                    <input type="text" class="form-control form-control-sm" :value="otherValues[attr.key]" @input="onOtherInput(attr.key, $event.target.value)" />
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Închide</button>
                    <button type="button" class="btn btn-primary" @click="handleSave">Salvează</button>
                </div>
            </div>
        </div>
    </div>
</template>
<script setup>
import { ref, reactive } from 'vue'

const props = defineProps({
    attributes: {
        type: Array,
        default: () => [
            { key: 'runner_name',      label: 'Nume' },
            { key: 'surname',          label: 'Prenume' },
            { key: 'gender',           label: 'Gen' },
            { key: 'yob',              label: 'An Nastere' },
            { key: 'club_id',          label: 'Club',                    display: r => r?.club?.club_name },
            { key: 'category_id',      label: 'Categorie',                display: r => r?.category?.category_name },
            { key: 'best_category_id', label: 'Cea mai bună categorie',  display: r => r?.best_category?.category_name },
            { key: 'category_valid',   label: 'Valabilitate categorie' },
            { key: 'license',          label: 'Licență' },
            { key: 'wre_id',           label: 'WRE ID' },
            { key: 'sprint_wre_place', label: 'Loc WRE Sprint' },
            { key: 'sprint_wre_rang',  label: 'Rang WRE Sprint' },
            { key: 'forest_wre_place', label: 'Loc WRE Forest' },
            { key: 'forest_wre_rang',  label: 'Rang WRE Forest' }
        ]
    }
})

const emit = defineEmits(['save'])

const modalRef = ref(null)
let modalInstance = null

const mainRunner = ref(null)
const mergedRunner = ref(null)
const otherValues = reactive({})
const selections = reactive({})

function show(main, merged) {
    mainRunner.value = main
    mergedRunner.value = merged

    Object.keys(otherValues).forEach(k => delete otherValues[k])
    Object.keys(selections).forEach(k => delete selections[k])
    props.attributes.forEach(a => {
        otherValues[a.key] = ''
        selections[a.key] = 'main'
    })

    if (!modalInstance) {
        modalInstance = new bootstrap.Modal(modalRef.value)
    }
    modalInstance.show()
}

function hide() {
    modalInstance?.hide()
}

function selectSource(key, source) {
    selections[key] = source
}

function onOtherInput(key, value) {
    otherValues[key] = value
    selections[key] = value ? 'other' : 'main'
}

function handleSave() {
    emit('save', {
        mainRunner: mainRunner.value,
        mergedRunner: mergedRunner.value,
        otherValues: { ...otherValues },
        selections: { ...selections }
    })
    hide()
}

defineExpose({ show })
</script>
<style scoped>
.selectable {
    cursor: pointer;
}
.selected {
    background-color: #d4edda !important;
}
</style>
